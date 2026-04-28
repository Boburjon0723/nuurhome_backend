const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

exports.getAllInventory = async (req, res) => {
    try {
        const inventory = await prisma.productInventory.findMany({
            include: {
                product: {
                    include: { category: true }
                }
            }
        });
        res.json(inventory);
    } catch (error) {
        console.error('Get Inventory Error:', error);
        res.status(500).json({ message: error.message });
    }
};

exports.getStockMovements = async (req, res) => {
    try {
        const movements = await prisma.stockMovement.findMany({
            orderBy: { createdAt: 'desc' },
            take: 1000 // Limit for performance
        });
        res.json(movements);
    } catch (error) {
        console.error('Get Movements Error:', error);
        res.status(500).json({ message: error.message });
    }
};

exports.addStock = async (req, res) => {
    const { productId, colorKey, qty, type = 'in' } = req.body;
    
    if (!productId || qty === undefined) {
        return res.status(400).json({ message: 'ProductId and qty are required' });
    }

    try {
        // 1. Create Stock Movement
        const movement = await prisma.stockMovement.create({
            data: {
                productId,
                colorKey,
                qty,
                type
            }
        });

        // 2. Update/Create Product Inventory
        const inventory = await prisma.productInventory.upsert({
            where: {
                productId_colorKey: {
                    productId,
                    colorKey: colorKey || null
                }
            },
            update: {
                stock: { increment: qty }
            },
            create: {
                productId,
                colorKey: colorKey || null,
                stock: qty
            }
        });

        // 3. Update Global Product Stock (Sum of all colors)
        const totalStock = await prisma.productInventory.aggregate({
            where: { productId },
            _sum: { stock: true }
        });

        await prisma.product.update({
            where: { id: productId },
            data: { stock: totalStock._sum.stock || 0 }
        });

        res.status(201).json({ movement, inventory });
    } catch (error) {
        console.error('Add Stock Error:', error);
        res.status(500).json({ message: error.message });
    }
};

exports.bulkUpdateInventory = async (req, res) => {
    const { productId, colorsMap, reason } = req.body;
    // colorsMap: { "Red": 10, "Blue": 5 }

    if (!productId || !colorsMap) {
        return res.status(400).json({ message: 'ProductId and colorsMap are required' });
    }

    try {
        const results = await prisma.$transaction(async (tx) => {
            const updates = [];
            let totalStock = 0;

            for (const [colorKey, stock] of Object.entries(colorsMap)) {
                const qty = Number(stock) || 0;
                totalStock += qty;

                const inv = await tx.productInventory.upsert({
                    where: {
                        productId_colorKey: {
                            productId,
                            colorKey
                        }
                    },
                    update: { stock: qty },
                    create: {
                        productId,
                        colorKey,
                        stock: qty
                    }
                });
                updates.push(inv);
            }

            // Also handle any colors NOT in the map (set them to 0 or leave as is?)
            // Usually, if we "save breakdown", we mean THIS IS THE NEW STATE.
            // But for simplicity, we only update provided colors.

            await tx.product.update({
                where: { id: productId },
                data: { stock: totalStock }
            });

            if (reason) {
                await tx.stockMovement.create({
                    data: {
                        productId,
                        qty: 0, // It's an adjustment, total is updated
                        type: 'adjustment',
                        customerName: reason
                    }
                });
            }

            return { updates, totalStock };
        });

        res.json(results);
    } catch (error) {
        console.error('Bulk Update Inventory Error:', error);
        res.status(500).json({ message: error.message });
    }
};
