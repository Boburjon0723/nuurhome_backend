const prisma = require('../lib/prisma');

exports.getAllCategories = async (req, res) => {
    try {
        const categories = await prisma.category.findMany({
            orderBy: { name_uz: 'asc' }
        });
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
        res.json({ message: 'Category deleted' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};
