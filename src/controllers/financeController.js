const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

// --- DEPARTMENTS ---
exports.getDepartments = async (req, res) => {
    try {
        const depts = await prisma.department.findMany({
            where: { is_active: true },
            orderBy: { sort_order: 'asc' }
        });
        res.json(depts);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.createDepartment = async (req, res) => {
    try {
        const { name_uz, name_ru, name_en, parent_id, sort_order } = req.body;
        const dept = await prisma.department.create({
            data: {
                name_uz,
                name_ru: name_ru || name_uz,
                name_en: name_en || name_uz,
                parent_id,
                sort_order: parseInt(sort_order) || 0
            }
        });
        res.status(201).json(dept);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.updateDepartment = async (req, res) => {
    try {
        const { id } = req.params;
        const { name_uz, name_ru, name_en, sort_order, is_active } = req.body;
        const dept = await prisma.department.update({
            where: { id },
            data: {
                name_uz,
                name_ru,
                name_en,
                sort_order: parseInt(sort_order),
                is_active
            }
        });
        res.json(dept);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// --- PARTNERS ---
exports.getPartners = async (req, res) => {
    try {
        const partners = await prisma.financePartner.findMany({
            where: { is_active: true },
            orderBy: { createdAt: 'desc' }
        });
        res.json(partners);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.createPartner = async (req, res) => {
    try {
        const { name_uz, name_ru, name_en, type } = req.body;
        const partner = await prisma.financePartner.create({
            data: {
                name_uz,
                name_ru: name_ru || name_uz,
                name_en: name_en || name_uz,
                type
            }
        });
        res.status(201).json(partner);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// --- PARTNER ENTRIES ---
exports.getPartnerEntries = async (req, res) => {
    try {
        const { from, to, partner_id } = req.query;
        const where = {};
        if (partner_id) where.partner_id = partner_id;
        if (from && to) {
            where.entry_date = { gte: from, lte: to };
        }
        
        const entries = await prisma.partnerFinanceEntry.findMany({
            where,
            include: { lines: true },
            orderBy: { entry_date: 'desc' }
        });
        res.json(entries);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.createPartnerEntry = async (req, res) => {
    try {
        const { partner_id, entry_type, amount_uzs, currency, entry_date, description, lines, responsible_person, warehouse } = req.body;
        
        const result = await prisma.$transaction(async (tx) => {
            const entry = await tx.partnerFinanceEntry.create({
                data: {
                    partner_id,
                    entry_type,
                    amount_uzs: parseFloat(amount_uzs),
                    currency,
                    entry_date,
                    description,
                    responsible_person,
                    warehouse,
                    status: 'completed'
                }
            });

            if (lines && lines.length > 0) {
                await tx.partnerFinanceEntryLine.createMany({
                    data: lines.map(ln => ({
                        entry_id: entry.id,
                        item_name: ln.item_name,
                        quantity_display: String(ln.quantity_display),
                        unit_price_uzs: parseFloat(ln.unit_price_uzs),
                        line_total_uzs: parseFloat(ln.line_total_uzs)
                    }))
                });
            }

            return entry;
        });

        res.status(201).json(result);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.deletePartnerEntry = async (req, res) => {
    try {
        const { id } = req.params;
        await prisma.partnerFinanceEntry.delete({
            where: { id }
        });
        res.json({ message: 'Deleted successfully' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// --- MATERIAL MOVEMENTS ---
exports.getMaterialMovements = async (req, res) => {
    try {
        const { from, to, department_id } = req.query;
        const where = {};
        if (department_id) where.department_id = department_id;
        if (from && to) {
            where.movement_date = { gte: from, lte: to };
        }

        const movements = await prisma.materialMovement.findMany({
            where,
            orderBy: { movement_date: 'desc' }
        });
        res.json(movements);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.createMaterialMovement = async (req, res) => {
    try {
        const { department_id, total_cost, movement_date, currency, note } = req.body;
        const movement = await prisma.materialMovement.create({
            data: {
                department_id,
                total_cost: parseFloat(total_cost),
                movement_date,
                currency: currency || 'UZS',
                note
            }
        });
        res.status(201).json(movement);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// --- EMPLOYEE PAYMENTS ---
exports.getPayouts = async (req, res) => {
    try {
        const { from, to } = req.query;
        const [advances, salaries] = await Promise.all([
            prisma.employeeAdvance.findMany({ where: { advance_date: { gte: from, lte: to } } }),
            prisma.employeeSalaryPayment.findMany({ where: { payment_date: { gte: from, lte: to } } })
        ]);

        const formatted = [
            ...advances.map(a => ({ ...a, kind: 'advance', date: a.advance_date })),
            ...salaries.map(s => ({ ...s, kind: 'salary', date: s.payment_date }))
        ];
        res.json(formatted);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};
