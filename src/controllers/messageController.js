const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

exports.createMessage = async (req, res) => {
    try {
        const { name, email, phone, subject, message } = req.body;
        const newMessage = await prisma.contactMessage.create({
            data: { name, email, phone, subject, message }
        });
        res.status(201).json({ success: true, message: newMessage });
    } catch (error) {
        console.error('Create Message Error:', error);
        res.status(500).json({ success: false, error: error.message });
    }
};

exports.getAllMessages = async (req, res) => {
    try {
        const messages = await prisma.contactMessage.findMany({
            orderBy: { created_at: 'desc' }
        });
        res.json(messages);
    } catch (error) {
        console.error('Get Messages Error:', error);
        res.status(500).json({ message: error.message });
    }
};
