const prisma = require('../lib/prisma');
const redisClient = require('../config/redis');

const CACHE_KEY_PRODUCTS = 'all_products';

exports.getAllProducts = async (req, res) => {
    try {
        // DB Fetch directly (Bypassing cache for troubleshooting)

        // DB Fallback
        const products = await prisma.product.findMany({
            include: { 
                category: true,
                inventory: true
            },
            orderBy: { createdAt: 'desc' }
        });
        
        // Try to update cache (async)
        try {
            await redisClient.setEx(CACHE_KEY_PRODUCTS, 3600, JSON.stringify(products));
        } catch (setCacheErr) {
            // Log set error but don't fail the request
        }

        res.json(products);
    } catch (error) {
        console.error('All Products Error:', error);
        res.status(500).json({ message: error.message });
    }
};

exports.getProductById = async (req, res) => {
    try {
        const product = await prisma.product.findUnique({
            where: { id: req.params.id },
            include: { category: true }
        });
        if (!product) return res.status(404).json({ message: 'Product not found' });
        res.json(product);
    } catch (error) {
        console.error('Get Product Error:', error);
        res.status(500).json({ message: error.message });
    }
};

exports.createProduct = async (req, res) => {
    try {
        console.log('Create Product Body:', req.body);
        const product = await prisma.product.create({
            data: req.body
        });
        await redisClient.del(CACHE_KEY_PRODUCTS);
        res.status(201).json(product);
    } catch (error) {
        console.error('Create Product ERROR:', error);
        res.status(500).json({ message: error.message });
    }
};

exports.updateProduct = async (req, res) => {
    try {
        console.log('Update Product Body:', req.body);
        const product = await prisma.product.update({
            where: { id: req.params.id },
            data: req.body
        });
        // Invalidate cache on update
        await redisClient.del(CACHE_KEY_PRODUCTS);
        res.json(product);
    } catch (error) {
        console.error('Update Product ERROR:', error);
        res.status(500).json({ message: error.message });
    }
};

exports.deleteProduct = async (req, res) => {
    try {
        await prisma.product.delete({
            where: { id: req.params.id }
        });
        await redisClient.del(CACHE_KEY_PRODUCTS);
        res.json({ message: 'Product deleted' });
    } catch (error) {
        console.error('Delete Product Error:', error);
        res.status(500).json({ message: error.message });
    }
};

exports.bulkUpdateCategoryColors = async (req, res) => {
    const { categoryId, colors, action } = req.body; // action: 'add', 'replace', 'remove'
    if (!categoryId || !Array.isArray(colors)) {
        return res.status(400).json({ message: 'CategoryId and colors array are required' });
    }

    try {
        const products = await prisma.product.findMany({
            where: { categoryId: categoryId || undefined }
        });

        if (products.length === 0) {
            return res.json({ message: 'No products found in this category' });
        }

        // Use sequential updates to avoid connection pool exhaustion
        for (const product of products) {
            let existingColors = Array.isArray(product.colors) ? product.colors : [];
            let newColors = [];

            if (action === 'add') {
                newColors = [...new Set([...existingColors, ...colors])];
            } else if (action === 'replace') {
                newColors = colors;
            } else if (action === 'remove') {
                newColors = existingColors.filter(c => !colors.includes(c));
            }

            await prisma.product.update({
                where: { id: product.id },
                data: { colors: newColors }
            });
        }

        await redisClient.del(CACHE_KEY_PRODUCTS);
        res.json({ message: `Successfully updated ${products.length} products` });
    } catch (error) {
        console.error('Bulk Update Colors Error:', error);
        res.status(500).json({ message: error.message });
    }
};

exports.getProductsByIds = async (req, res) => {
    const { ids } = req.query;
    if (!ids) {
        return res.status(400).json({ message: 'ID lar ko\'rsatilmadi' });
    }

    const idList = ids.split(',').filter(id => id.trim() !== '');

    try {
        const products = await prisma.product.findMany({
            where: {
                id: { in: idList }
            },
            include: {
                category: true
            }
        });
        res.json(products);
    } catch (error) {
        console.error('Get Products By Ids Error:', error);
        res.status(500).json({ message: error.message });
    }
};
