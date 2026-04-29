const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

exports.getAllAlbumImages = async (req, res) => {
    try {
        const images = await prisma.albumImage.findMany({
            where: { is_active: true },
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
        const { image_url, title_uz, title_ru, title_en, format } = req.body;
        const newImage = await prisma.albumImage.create({
            data: { image_url, title_uz, title_ru, title_en, format }
        });
        res.status(201).json(newImage);
    } catch (error) {
        console.error('Create Album Image Error:', error);
        res.status(500).json({ message: error.message });
    }
};
