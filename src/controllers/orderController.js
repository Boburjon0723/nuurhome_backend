const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

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

// Get all orders
exports.getOrders = async (req, res) => {
  try {
    const orders = await prisma.order.findMany({
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

// Delete an order
exports.deleteOrder = async (req, res) => {
  const { id } = req.params;
  try {
    await prisma.order.delete({
      where: { id }
    });
    res.json({ message: 'Order deleted successfully' });
  } catch (error) {
    console.error('Error deleting order:', error);
    res.status(500).json({ message: 'Server error deleting order', error: error.message });
  }
};

// Bulk delete orders
exports.deleteOrders = async (req, res) => {
  const { ids } = req.body;
  if (!Array.isArray(ids) || ids.length === 0) {
    return res.status(400).json({ message: 'No IDs provided' });
  }
  try {
    const result = await prisma.order.deleteMany({
      where: {
        id: { in: ids }
      }
    });
    res.json({ message: `Deleted ${result.count} orders successfully` });
  } catch (error) {
    console.error('Error bulk deleting orders:', error);
    res.status(500).json({ message: 'Server error bulk deleting orders', error: error.message });
  }
};
