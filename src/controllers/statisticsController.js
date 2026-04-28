const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const redisClient = require('../config/redis');

/**
 * Statistik hisobotlarni hisoblash:
 * - Faqat "tugallangan" statusdagi buyurtmalar
 * - Tanlangan davr oralig'ida
 * - Moliya (Transaction) xarajatlari bilan birga
 */
exports.getAnalytics = async (req, res) => {
  try {
    const { start, end } = req.query;
    
    // Check Redis Cache
    const cacheKey = `analytics_${start || 'all'}_${end || 'all'}`;
    try {
      const cached = await redisClient.get(cacheKey);
      if (cached) {
        console.log('Serving analytics from cache');
        return res.json(JSON.parse(cached));
      }
    } catch (cacheErr) {
      console.warn('Redis Cache Error (Analytics):', cacheErr.message);
    }

    // Davrni aniqlash
    let startDate = start ? new Date(start) : new Date(new Date().setDate(new Date().getDate() - 30));
    let endDate = end ? new Date(end) : new Date();

    if (isNaN(startDate.getTime())) startDate = new Date(new Date().setDate(new Date().getDate() - 30));
    if (isNaN(endDate.getTime())) endDate = new Date();

    // 1. Tugallangan buyurtmalar (Case-insensitive qidiruv)
    // Tizimda turli xil yozilgan bo'lishi mumkin: Completed, completed, Tugallandi, tugallandi...
    const completedOrders = await prisma.order.findMany({
      where: {
        deleted_at: null,
        status: { 
          in: ['completed', 'Completed', 'tugallandi', 'Tugallandi', 'tugallangan', 'Tugallangan'],
        },
        updated_at: {
          gte: startDate,
          lte: endDate,
        },
      },
      include: {
        order_items: {
          include: {
            product: {
              include: { 
                category: true 
              }
            }
          }
        },
      },
      orderBy: { updated_at: 'asc' }
    });

    // 2. Moliya xarajatlarini yuklash
    const transactions = await prisma.transaction.findMany({
      where: {
        date: {
          gte: startDate,
          lte: endDate,
        },
      },
    });

    // 3. Agregatsiya va hisob-kitoblar
    let totalSales = 0;
    let totalExpense = 0;
    
    const categoryStats = {};
    const productStats = {};
    const customerStats = {};
    const customerModelStats = {};
    const salesTrendMap = {};
    const financeTrendMap = {};

    for (const order of completedOrders) {
      const orderTotal = Number(order.total) || 0;
      totalSales += orderTotal;

      const dateObj = order.updated_at || new Date();
      const dayKey = dateObj.toISOString().split('T')[0];
      salesTrendMap[dayKey] = (salesTrendMap[dayKey] || 0) + orderTotal;
      
      if (!financeTrendMap[dayKey]) financeTrendMap[dayKey] = { date: dayKey, income: 0, expense: 0 };
      financeTrendMap[dayKey].income += orderTotal;

      const cName = (order.customer_name || '').trim() || 'Nomaʼlum';
      const cPhone = (order.customer_phone || '').trim() || '—';
      const cKey = `${cName}_${cPhone}`;

      if (order.order_items) {
        for (const item of order.order_items) {
          const qty = Number(item.quantity) || 0;
          const price = Number(item.product_price) || 0;
          const lineVal = qty * price;

          // Kategoriya
          const catName = item.product?.category?.name || item.product?.category?.name_uz || 'Boshqa';
          if (!categoryStats[catName]) {
            categoryStats[catName] = { name: catName, revenue: 0, qtyPieces: 0, qtyKg: 0 };
          }
          categoryStats[catName].revenue += lineVal;
          if (item.product?.is_kg) {
            categoryStats[catName].qtyKg += qty;
          } else {
            categoryStats[catName].qtyPieces += qty;
          }

          // Mahsulot (Artikul va Kategoriyasi bilan)
          const pName = item.product_name || item.product?.name || 'Nomaʼlum';
          const sku = item.sku || item.product?.sku || '—';
          const pKey = item.product_id || `${pName}_${sku}`;
          
          if (!productStats[pKey]) {
            productStats[pKey] = { 
              name: pName, 
              sku: sku,
              categoryName: catName,
              revenue: 0, 
              qty: 0 
            };
          }
          productStats[pKey].revenue += lineVal;
          productStats[pKey].qty += qty;

          // Mijoz x Model
          const modelCode = item.size || item.sku || pName;
          const cmKey = `${cKey}|||${modelCode}`;
          if (!customerModelStats[cmKey]) {
            customerModelStats[cmKey] = { name: cName, phone: cPhone, modelCode, qty: 0, revenue: 0 };
          }
          customerModelStats[cmKey].qty += qty;
          customerModelStats[cmKey].revenue += lineVal;
        }
      }

      // Mijozlar
      if (!customerStats[cKey]) {
        customerStats[cKey] = { name: cName, phone: cPhone, total: 0, ordersCount: 0, itemQty: 0 };
      }
      customerStats[cKey].total += orderTotal;
      customerStats[cKey].ordersCount += 1;
      if (order.order_items) {
        for (const item of order.order_items) {
          customerStats[cKey].itemQty += Number(item.quantity) || 1;
        }
      }
    }

    for (const trans of transactions) {
      if (trans.type === 'EXPENSE') {
        const amt = Number(trans.amount) || 0;
        totalExpense += amt;
        const tDate = trans.date || new Date();
        const dayKey = tDate.toISOString().split('T')[0];
        if (!financeTrendMap[dayKey]) financeTrendMap[dayKey] = { date: dayKey, income: 0, expense: 0 };
        financeTrendMap[dayKey].expense += amt;
      }
    }

    const categories = Object.values(categoryStats).sort((a, b) => b.revenue - a.revenue);
    const products = Object.values(productStats).sort((a, b) => b.qty - a.qty).slice(0, 500);
    const customers = Object.values(customerStats).sort((a, b) => b.total - a.total).slice(0, 100);
    const customerModels = Object.values(customerModelStats).sort((a, b) => b.revenue - a.revenue).slice(0, 100);
    const salesTrend = Object.entries(salesTrendMap)
      .map(([date, amount]) => ({ date, amount }))
      .sort((a, b) => a.date.localeCompare(b.date));
    
    const financeTrend = Object.values(financeTrendMap).sort((a, b) => a.date.localeCompare(b.date));

    const productsCount = await prisma.product.count({ where: { isActive: true } });
    const employeesCount = await prisma.employee.count();

    const resultData = {
      summary: {
        totalSales,
        totalExpense,
        totalIncome: totalSales,
        ordersCount: completedOrders.length,
        productsCount,
        employeesCount
      },
      categories,
      products,
      customers,
      customerModels,
      salesTrend,
      financeTrend,
    };

    // Save to Cache for 5 minutes
    try {
      await redisClient.setEx(cacheKey, 300, JSON.stringify(resultData));
    } catch (setCacheErr) {}

    res.json(resultData);

  } catch (error) {
    console.error('Statistika hisoblashda xatolik:', error);
    res.status(500).json({ 
      message: 'Statistika maʼlumotlarini yuklab boʻlmadi', 
      error: error.message 
    });
  }
};
