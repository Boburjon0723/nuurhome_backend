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
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 50;
    const skip = (page - 1) * limit;

    const [orders, total] = await Promise.all([
      prisma.order.findMany({
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
        skip,
        take: limit,
      }),
      prisma.order.count({ where: { deleted_at: null } })
    ]);

    res.json({
      orders,
      pagination: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit)
      }
    });
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
      customer_address,
      total,
      status,
      source,
      note,
      payment_method_detail,
      receipt_url,
      order_items,
      items,
      created_by
    } = req.body;

    const itemsToProcess = order_items || items || [];
    const createItems = [];
    for (const item of itemsToProcess) {
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

    const order = await prisma.$transaction(async (tx) => {
      // 1. Create the order
      const newOrder = await tx.order.create({
        data: {
          customer_name,
          customer_phone,
          customer_address,
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

      // 2. Deduct stock for each item
      for (const item of newOrder.order_items) {
        if (!item.product_id) continue;

        const qtyToDeduct = Number(item.quantity) || 0;
        if (qtyToDeduct <= 0) continue;

        // A. Update Color-specific Inventory if color is specified
        if (item.color) {
          await tx.productInventory.upsert({
            where: {
              productId_colorKey: {
                productId: item.product_id,
                colorKey: item.color
              }
            },
            update: {
              stock: { decrement: qtyToDeduct }
            },
            create: {
              productId: item.product_id,
              colorKey: item.color,
              stock: -qtyToDeduct
            }
          });
        } else {
          // If no color, deduct from the "null" color inventory
          await tx.productInventory.upsert({
            where: {
              productId_colorKey: {
                productId: item.product_id,
                colorKey: null
              }
            },
            update: {
              stock: { decrement: qtyToDeduct }
            },
            create: {
              productId: item.product_id,
              colorKey: null,
              stock: -qtyToDeduct
            }
          });
        }

        // B. Update Global Product Stock
        await tx.product.update({
          where: { id: item.product_id },
          data: {
            stock: { decrement: qtyToDeduct }
          }
        });

        // C. Create Stock Movement
        await tx.stockMovement.create({
          data: {
            productId: item.product_id,
            colorKey: item.color || null,
            qty: -qtyToDeduct,
            type: 'out',
            orderId: newOrder.id,
            orderNumber: newOrder.order_number,
            customerName: customer_name || 'Mijoz'
          }
        });
      }

      return newOrder;
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

    const updatedOrder = await prisma.$transaction(async (tx) => {
      // 1. Get old items to restore stock
      const oldOrder = await tx.order.findUnique({
        where: { id },
        include: { order_items: true }
      });

      if (oldOrder && (oldOrder.status !== 'cancelled')) {
        for (const item of oldOrder.order_items) {
          if (!item.product_id) continue;
          const qty = Number(item.quantity) || 0;
          
          // Restore Color Inventory
          await tx.productInventory.update({
            where: { productId_colorKey: { productId: item.product_id, colorKey: item.color || null } },
            data: { stock: { increment: qty } }
          });
          // Restore Global Stock
          await tx.product.update({
            where: { id: item.product_id },
            data: { stock: { increment: qty } }
          });
          // Create Stock Movement (In)
          await tx.stockMovement.create({
            data: {
              productId: item.product_id,
              colorKey: item.color || null,
              qty: qty,
              type: 'in',
              orderId: id,
              orderNumber: oldOrder.order_number,
              customerName: `Update Restore: ${oldOrder.customer_name}`
            }
          });
        }
      }

      // 2. Update order base info
      await tx.order.update({
        where: { id },
        data: {
          customer_name,
          customer_phone,
          customer_address,
          total,
          status,
          source,
          note,
          payment_method_detail,
          receipt_url,
        }
      });

      // 3. Update items
      const itemsToProcess = order_items || [];
      if (itemsToProcess.length > 0) {
        await tx.orderItem.deleteMany({ where: { order_id: id } });
        const rows = [];
        for (const item of itemsToProcess) {
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

          // Deduct New Stock (if not cancelled)
          if (status !== 'cancelled' && resolvedProductId) {
            const qty = Number(item.quantity) || 0;
            // Update Color Inventory
            await tx.productInventory.upsert({
              where: { productId_colorKey: { productId: resolvedProductId, colorKey: item.color || null } },
              update: { stock: { decrement: qty } },
              create: { productId: resolvedProductId, colorKey: item.color || null, stock: -qty }
            });
            // Update Global Stock
            await tx.product.update({
              where: { id: resolvedProductId },
              data: { stock: { decrement: qty } }
            });
            // Create Stock Movement (Out)
            await tx.stockMovement.create({
              data: {
                productId: resolvedProductId,
                colorKey: item.color || null,
                qty: -qty,
                type: 'out',
                orderId: id,
                orderNumber: oldOrder.order_number,
                customerName: `Update Deduct: ${customer_name}`
              }
            });
          }
        }
        await tx.orderItem.createMany({ data: rows });
      }

      return tx.order.findUnique({
        where: { id },
        include: { order_items: true }
      });
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
    const updatedOrder = await prisma.$transaction(async (tx) => {
      const oldOrder = await tx.order.findUnique({
        where: { id },
        include: { order_items: true }
      });

      if (!oldOrder) throw new Error('Order not found');

      // If moving TO cancelled from something NOT cancelled -> Restore stock
      if (status === 'cancelled' && oldOrder.status !== 'cancelled') {
        for (const item of oldOrder.order_items) {
          if (!item.product_id) continue;
          const qty = Number(item.quantity) || 0;
          await tx.productInventory.update({
            where: { productId_colorKey: { productId: item.product_id, colorKey: item.color || null } },
            data: { stock: { increment: qty } }
          });
          await tx.product.update({
            where: { id: item.product_id },
            data: { stock: { increment: qty } }
          });
          await tx.stockMovement.create({
            data: {
              productId: item.product_id,
              colorKey: item.color || null,
              qty: qty,
              type: 'in',
              orderId: id,
              orderNumber: oldOrder.order_number,
              customerName: `Status Cancelled: ${oldOrder.customer_name}`
            }
          });
        }
      } 
      // If moving FROM cancelled to something NOT cancelled -> Deduct stock
      else if (status !== 'cancelled' && oldOrder.status === 'cancelled') {
        for (const item of oldOrder.order_items) {
          if (!item.product_id) continue;
          const qty = Number(item.quantity) || 0;
          await tx.productInventory.upsert({
            where: { productId_colorKey: { productId: item.product_id, colorKey: item.color || null } },
            update: { stock: { decrement: qty } },
            create: { productId: item.product_id, colorKey: item.color || null, stock: -qty }
          });
          await tx.product.update({
            where: { id: item.product_id },
            data: { stock: { decrement: qty } }
          });
          await tx.stockMovement.create({
            data: {
              productId: item.product_id,
              colorKey: item.color || null,
              qty: -qty,
              type: 'out',
              orderId: id,
              orderNumber: oldOrder.order_number,
              customerName: `Status Restore: ${oldOrder.customer_name}`
            }
          });
        }
      }

      return tx.order.update({
        where: { id },
        data: { status }
      });
    });

    res.json(updatedOrder);
  } catch (error) {
    console.error('Error updating order status:', error);
    res.status(500).json({ message: 'Server error updating order status', error: error.message });
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

// Get orders by User ID
exports.getOrdersByUserId = async (req, res) => {
  const { userId } = req.params;
  if (!userId) {
    return res.status(400).json({ message: 'User ID is required' });
  }
  try {
    const orders = await prisma.order.findMany({
      where: { created_by: userId },
      include: {
        order_items: {
          include: {
            product: {
              include: { category: true }
            }
          }
        }
      },
      orderBy: { created_at: 'desc' }
    });
    res.json(orders);
  } catch (error) {
    console.error('Error fetching orders by user:', error);
    res.status(500).json({ message: 'Server error fetching orders', error: error.message });
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
