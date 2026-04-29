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
        const { name, name_uz, name_ru, name_en, image_url, image, slug } = req.body;
        
        // Generate slug if missing
        const finalSlug = slug || (name_uz || name || 'category').toLowerCase()
            .replace(/[^a-z0-9]+/g, '-')
            .replace(/(^-|-$)/g, '') + '-' + Math.random().toString(36).substring(2, 7);

        const category = await prisma.category.create({
            data: {
                name,
                name_uz,
                name_ru,
                name_en,
                image: image || image_url,
                slug: finalSlug
            }
        });
        await redisClient.del(CACHE_KEY_CATEGORIES);
        res.status(201).json(category);
    } catch (error) {
        console.error('Create Category Error:', error);
        res.status(500).json({ message: error.message });
    }
};

exports.updateCategory = async (req, res) => {
    try {
        const { name, name_uz, name_ru, name_en, image_url, image, slug } = req.body;
        
        const category = await prisma.category.update({
            where: { id: req.params.id },
            data: {
                name,
                name_uz,
                name_ru,
                name_en,
                image: image || image_url,
                slug: slug || undefined
            }
        });
        await redisClient.del(CACHE_KEY_CATEGORIES);
        res.json(category);
    } catch (error) {
        console.error('Update Category Error:', error);
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
