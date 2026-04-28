const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

exports.getAllEmployees = async (req, res) => {
    try {
        const employees = await prisma.employee.findMany({
            include: {
                advances: true,
                salaries: true
            },
            orderBy: { createdAt: 'desc' }
        });
        res.json(employees);
    } catch (error) {
        console.error('Get All Employees Error:', error);
        res.status(500).json({ message: error.message });
    }
};

exports.getEmployeeById = async (req, res) => {
    try {
        const employee = await prisma.employee.findUnique({
            where: { id: req.params.id },
            include: {
                advances: true,
                salaries: true
            }
        });
        if (!employee) return res.status(404).json({ message: 'Employee not found' });
        res.json(employee);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.createEmployee = async (req, res) => {
    try {
        const employee = await prisma.employee.create({
            data: req.body
        });
        res.status(201).json(employee);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.updateEmployee = async (req, res) => {
    try {
        const employee = await prisma.employee.update({
            where: { id: req.params.id },
            data: req.body
        });
        res.json(employee);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.deleteEmployee = async (req, res) => {
    try {
        await prisma.employee.delete({
            where: { id: req.params.id }
        });
        res.json({ message: 'Employee deleted' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// --- Financials ---

exports.addAdvance = async (req, res) => {
    const { employeeId, amount, date, note } = req.body;
    try {
        const advance = await prisma.employeeAdvance.create({
            data: {
                employee_id: employeeId,
                amount: amount,
                advance_date: date,
                note: note
            }
        });
        res.status(201).json(advance);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.addSalaryPayment = async (req, res) => {
    const { employeeId, amount, date, note } = req.body;
    try {
        const payment = await prisma.employeeSalaryPayment.create({
            data: {
                employee_id: employeeId,
                amount: amount,
                payment_date: date,
                note: note
            }
        });
        res.status(201).json(payment);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.deleteAdvance = async (req, res) => {
    try {
        await prisma.employeeAdvance.delete({ where: { id: req.params.id } });
        res.json({ message: 'Advance deleted' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.deleteSalaryPayment = async (req, res) => {
    try {
        await prisma.employeeSalaryPayment.delete({ where: { id: req.params.id } });
        res.json({ message: 'Salary payment deleted' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.deleteAllAdvances = async (req, res) => {
    try {
        const { ids } = req.body;
        if (!ids || !ids.length) return res.status(400).json({ message: 'No IDs provided' });
        await prisma.employeeAdvance.deleteMany({ where: { id: { in: ids } } });
        res.json({ message: 'Advances bulk deleted' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.deleteAllSalaryPayments = async (req, res) => {
    try {
        const { ids } = req.body;
        if (!ids || !ids.length) return res.status(400).json({ message: 'No IDs provided' });
        await prisma.employeeSalaryPayment.deleteMany({ where: { id: { in: ids } } });
        res.json({ message: 'Salary payments bulk deleted' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// --- Month Closures ---

exports.getClosures = async (req, res) => {
    try {
        const closures = await prisma.employeePayrollMonthClosure.findMany({
            orderBy: { period_ym: 'desc' }
        });
        res.json(closures);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.addClosure = async (req, res) => {
    const { period_ym, source } = req.body;
    try {
        const closure = await prisma.employeePayrollMonthClosure.create({
            data: {
                period_ym: period_ym,
                source: source || 'crm'
            }
        });
        res.status(201).json(closure);
    } catch (error) {
        res.status(500).json({ message: error.message, code: error.code });
    }
};

exports.deleteClosure = async (req, res) => {
    try {
        await prisma.employeePayrollMonthClosure.delete({
            where: { period_ym: req.params.period_ym }
        });
        res.json({ message: 'Closure removed' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// --- Leave Requests ---

exports.getLeaves = async (req, res) => {
    try {
        const leaves = await prisma.employeeLeaveRequest.findMany({
            where: { status: 'approved' },
            orderBy: { resolved_at: 'desc' },
            take: 3000
        });
        res.json(leaves);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};
