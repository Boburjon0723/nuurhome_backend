const prisma = require('../lib/prisma');
const redisClient = require('../config/redis');

const CACHE_KEY_CATEGORIES = 'all_categories';

exports.getAllCategories = async (req, res) => {
    try {
        // Try Cache
        try {
            const cached = await redisClient.get(CACHE_KEY_CATEGORIES);
            if (cached) return res.json(JSON.parse(cached));
        } catch (err) { console.error('Redis Get Categories Error:', err); }

        const categories = await prisma.category.findMany({
            orderBy: { name_uz: 'asc' }
        });

        // Set Cache
        try {
            await redisClient.setEx(CACHE_KEY_CATEGORIES, 86400, JSON.stringify(categories));
        } catch (err) { console.error('Redis Set Categories Error:', err); }

        res.json(categories);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.createCategory = async (req, res) => {
    try {
        const category = await prisma.category.create({
            data: req.body
        });
        await redisClient.del(CACHE_KEY_CATEGORIES);
        res.status(201).json(category);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.updateCategory = async (req, res) => {
    try {
        const category = await prisma.category.update({
            where: { id: req.params.id },
            data: req.body
        });
        await redisClient.del(CACHE_KEY_CATEGORIES);
        res.json(category);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.deleteCategory = async (req, res) => {
    try {
        await prisma.category.delete({
            where: { id: req.params.id }
        });
        await redisClient.del(CACHE_KEY_CATEGORIES);
        res.json({ message: 'Category deleted' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};
