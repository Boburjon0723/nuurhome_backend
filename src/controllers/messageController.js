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
        const { status } = req.query;
        const where = {};
        if (status && status !== 'all') {
            where.status = status;
        }

        const messages = await prisma.contactMessage.findMany({
            where,
            orderBy: { created_at: 'desc' }
        });
        res.json(messages);
    } catch (error) {
        console.error('Get Messages Error:', error);
        res.status(500).json({ message: error.message });
    }
};

exports.updateMessageStatus = async (req, res) => {
    try {
        const { id } = req.params;
        const { status } = req.body;
        const updatedMessage = await prisma.contactMessage.update({
            where: { id },
            data: { status }
        });
        res.json(updatedMessage);
    } catch (error) {
        console.error('Update Message Status Error:', error);
        res.status(500).json({ message: error.message });
    }
};

exports.deleteMessage = async (req, res) => {
    try {
        const { id } = req.params;
        await prisma.contactMessage.delete({
            where: { id }
        });
        res.json({ success: true, message: 'Message deleted' });
    } catch (error) {
        console.error('Delete Message Error:', error);
        res.status(500).json({ message: error.message });
    }
};
