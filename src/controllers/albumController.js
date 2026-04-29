const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

exports.getAllAlbumImages = async (req, res) => {
    try {
        const images = await prisma.albumImage.findMany({
            orderBy: { created_at: 'desc' }
        });
        res.json(images);
    } catch (error) {
        console.error('Get Album Images Error:', error);
        res.status(500).json({ message: error.message });
    }
};

exports.createAlbumImage = async (req, res) => {
    try {
        const { id, image_url, title_uz, title_ru, title_en, format, is_active } = req.body;
        
        if (id) {
            const updated = await prisma.albumImage.upsert({
                where: { id },
                update: { image_url, title_uz, title_ru, title_en, format, is_active },
                create: { image_url, title_uz, title_ru, title_en, format, is_active }
            });
            return res.json(updated);
        }

        const newImage = await prisma.albumImage.create({
            data: { image_url, title_uz, title_ru, title_en, format, is_active: is_active !== undefined ? is_active : true }
        });
        res.status(201).json(newImage);
    } catch (error) {
        console.error('Create Album Image Error:', error);
        res.status(500).json({ message: error.message });
    }
};

exports.deleteAlbumImage = async (req, res) => {
    try {
        const { id } = req.params;
        await prisma.albumImage.delete({ where: { id } });
        res.json({ success: true });
    } catch (error) {
        console.error('Delete Album Image Error:', error);
        res.status(500).json({ message: error.message });
    }
};
