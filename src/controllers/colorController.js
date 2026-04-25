const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

exports.getAllColors = async (req, res) => {
    try {
        const colors = await prisma.color.findMany({
            orderBy: { name: 'asc' }
        });
        res.json(colors);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.createColor = async (req, res) => {
    try {
        const color = await prisma.color.create({
            data: {
                name: req.body.name,
                hex: req.body.hex || null
            }
        });
        res.status(201).json(color);
    } catch (error) {
        // Handle unique constraint error
        if (error.code === 'P2002') {
            return res.status(400).json({ message: 'Bu rang allaqachon mavjud' });
        }
        res.status(500).json({ message: error.message });
    }
};

exports.deleteColor = async (req, res) => {
    try {
        await prisma.color.delete({
            where: { id: req.params.id }
        });
        res.json({ message: 'Rang o\'chirildi' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};
