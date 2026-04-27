const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

// Get all import history
exports.getAllImports = async (req, res) => {
    try {
        const imports = await prisma.excelImportHistory.findMany({
            orderBy: { importDate: 'desc' }
        });
        res.json(imports);
    } catch (error) {
        console.error('Error fetching import history:', error);
        res.status(500).json({ message: 'Error fetching import history' });
    }
};

// Save a new import
exports.saveImport = async (req, res) => {
    try {
        const { fileName, items } = req.body;
        
        if (!fileName || !items) {
            return res.status(400).json({ message: 'File name and items are required' });
        }

        const newImport = await prisma.excelImportHistory.create({
            data: {
                fileName,
                items: items, // JSON
                importDate: new Date()
            }
        });
        
        res.status(201).json(newImport);
    } catch (error) {
        console.error('Error saving import:', error);
        res.status(500).json({ message: 'Error saving import', error: error.message });
    }
};

// Delete an import
exports.deleteImport = async (req, res) => {
    try {
        const { id } = req.params;
        await prisma.excelImportHistory.delete({
            where: { id }
        });
        res.json({ message: 'Import deleted successfully' });
    } catch (error) {
        console.error('Error deleting import:', error);
        res.status(500).json({ message: 'Error deleting import' });
    }
};
