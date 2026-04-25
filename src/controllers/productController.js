const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const redisClient = require('../config/redis');

const CACHE_KEY_PRODUCTS = 'all_products';

exports.getAllProducts = async (req, res) => {
    try {
        const cached = await redisClient.get(CACHE_KEY_PRODUCTS);
        if (cached) return res.json(JSON.parse(cached));

        const products = await prisma.product.findMany({
            include: { category: true },
            orderBy: { createdAt: 'desc' }
        });
        
        await redisClient.setEx(CACHE_KEY_PRODUCTS, 3600, JSON.stringify(products));
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
        res.json({ message: 'Product deleted' });
    } catch (error) {
        console.error('Delete Product Error:', error);
        res.status(500).json({ message: error.message });
    }
};
