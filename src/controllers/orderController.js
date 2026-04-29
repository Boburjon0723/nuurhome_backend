const prisma = require('../lib/prisma');

async function resolveOrderItemProductId(item) {
  const rawId = String(item?.product_id || '').trim();
  if (rawId) {
    const byId = await prisma.product.findUnique({
      where: { id: rawId },
      select: { id: true }
    });
    if (byId?.id) return byId.id;
  }

  const skuCandidate = String(item?.sku || item?.size || '').trim();
  if (skuCandidate) {
    const bySku = await prisma.product.findFirst({
      where: { sku: { equals: skuCandidate, mode: 'insensitive' } },
      select: { id: true }
    });
    if (bySku?.id) return bySku.id;
  }
  return null;
}

// Get all active orders (not soft-deleted)
exports.getOrders = async (req, res) => {
  try {
    const orders = await prisma.order.findMany({
      where: { deleted_at: null },
      include: {
        order_items: {
          include: {
            product: {
              include: { category: true }
            }
          }
        },
        user: { select: { fullname: true } },
      },
      orderBy: { created_at: 'desc' },
    });
    res.json(orders);
  } catch (error) {
    console.error('Error fetching orders:', error);
    res.status(500).json({ message: 'Server error fetching orders' });
  }
};

// Get only soft-deleted orders (Trash)
exports.getDeletedOrders = async (req, res) => {
  try {
    const orders = await prisma.order.findMany({
      where: { deleted_at: { not: null } },
      include: {
        order_items: {
          include: {
            product: {
              include: { category: true }
            }
          }
        },
        user: { select: { fullname: true } },
      },
      orderBy: { deleted_at: 'desc' },
    });
    res.json(orders);
  } catch (error) {
    console.error('Error fetching trashed orders:', error);
    res.status(500).json({ message: 'Server error fetching trashed orders' });
  }
};

// Get order by ID
exports.getOrderById = async (req, res) => {
  try {
    const { id } = req.params;
    const order = await prisma.order.findUnique({
      where: { id },
      include: {
        order_items: {
          include: {
            product: {
              include: { category: true }
            }
          }
        },
      }
    });
    if (!order) {
      return res.status(404).json({ message: 'Order not found' });
    }
    res.json(order);
  } catch (error) {
    console.error('Error fetching order:', error);
    res.status(500).json({ message: 'Server error fetching order' });
  }
};

// Create an order
exports.createOrder = async (req, res) => {
  try {
    const {
      customer_name,
      customer_phone,
      total,
      status,
      source,
      note,
      payment_method_detail,
      receipt_url,
      order_items,
      created_by
    } = req.body;

    const createItems = [];
    for (const item of (order_items || [])) {
      const resolvedProductId = await resolveOrderItemProductId(item);
      createItems.push({
        product_id: resolvedProductId,
        product_name: item.product_name,
        quantity: item.quantity,
        product_price: item.product_price || item.price || 0,
        image_url: item.image_url,
        sku: item.sku,
        size: item.size,
        color: item.color,
        local_note: item.local_note,
        rope_weight_kg: item.rope_weight_kg
      });
    }

    const order = await prisma.order.create({
      data: {
        customer_name,
        customer_phone,
        total: total || 0,
        status: status || 'new',
        source: source || 'dokon',
        note,
        payment_method_detail,
        receipt_url,
        created_by,
        order_items: {
          create: createItems
        }
      },
      include: {
        order_items: true
      }
    });

    res.status(201).json(order);
  } catch (error) {
    console.error('Error creating order:', error);
    res.status(500).json({ 
      message: 'Server error creating order',
      error: error.message,
      details: error
    });
  }
};

// Update an order
exports.updateOrder = async (req, res) => {
  const { id } = req.params;
  try {
    const {
      customer_name,
      customer_phone,
      total,
      status,
      source,
      note,
      payment_method_detail,
      receipt_url,
      order_items,
    } = req.body;

    await prisma.order.update({
      where: { id },
      data: {
        customer_name,
        customer_phone,
        total,
        status,
        source,
        note,
        payment_method_detail,
        receipt_url,
      }
    });

    if (order_items && Array.isArray(order_items)) {
      await prisma.orderItem.deleteMany({ where: { order_id: id } });
      const rows = [];
      for (const item of order_items) {
        const resolvedProductId = await resolveOrderItemProductId(item);
        rows.push({
          order_id: id,
          product_id: resolvedProductId,
          product_name: item.product_name,
          quantity: item.quantity,
          product_price: item.product_price || item.price || 0,
          image_url: item.image_url,
          sku: item.sku,
          size: item.size,
          color: item.color,
          local_note: item.local_note,
          rope_weight_kg: item.rope_weight_kg
        });
      }
      await prisma.orderItem.createMany({
        data: rows
      });
    }

    const updatedOrder = await prisma.order.findUnique({
      where: { id },
      include: { order_items: true }
    });

    res.json(updatedOrder);
  } catch (error) {
    console.error('Error updating order:', error);
    res.status(500).json({ message: 'Server error updating order', error: error.message });
  }
};

// Update order status
exports.updateOrderStatus = async (req, res) => {
  const { id } = req.params;
  const { status } = req.body;
  try {
    const updatedOrder = await prisma.order.update({
      where: { id },
      data: { status }
    });
    res.json(updatedOrder);
  } catch (error) {
    console.error('Error updating order status:', error);
    res.status(500).json({ message: 'Server error updating order status' });
  }
};

// Soft delete an order (move to trash)
exports.deleteOrder = async (req, res) => {
  const { id } = req.params;
  try {
    await prisma.order.update({
      where: { id },
      data: { deleted_at: new Date() }
    });
    res.json({ message: 'Order moved to trash' });
  } catch (error) {
    console.error('Error moving order to trash:', error);
    res.status(500).json({ message: 'Server error moving order to trash', error: error.message });
  }
};

// Soft bulk delete orders
exports.deleteOrders = async (req, res) => {
  const { ids } = req.body;
  if (!Array.isArray(ids) || ids.length === 0) {
    return res.status(400).json({ message: 'No IDs provided' });
  }
  try {
    const result = await prisma.order.updateMany({
      where: {
        id: { in: ids }
      },
      data: { deleted_at: new Date() }
    });
    res.json({ message: `${result.count} orders moved to trash` });
  } catch (error) {
    console.error('Error bulk moving orders to trash:', error);
    res.status(500).json({ message: 'Server error moving orders to trash', error: error.message });
  }
};

// Restore a soft-deleted order
exports.restoreOrder = async (req, res) => {
  const { id } = req.params;
  try {
    await prisma.order.update({
      where: { id },
      data: { deleted_at: null }
    });
    res.json({ message: 'Order restored successfully' });
  } catch (error) {
    console.error('Error restoring order:', error);
    res.status(500).json({ message: 'Server error restoring order', error: error.message });
  }
};

// Permanently delete an order from trash
exports.permanentDeleteOrder = async (req, res) => {
  const { id } = req.params;
  try {
    await prisma.order.delete({
      where: { id }
    });
    res.json({ message: 'Order permanently deleted' });
  } catch (error) {
    console.error('Error permanently deleting order:', error);
    res.status(500).json({ message: 'Server error permanently deleting order', error: error.message });
  }
};
