const express = require('express');
const router = express.Router();
const employeeController = require('../controllers/employeeController');

// Static routes must come BEFORE dynamic routes like /:id
router.get('/leaves', employeeController.getLeaves);
router.get('/closures', employeeController.getClosures);

router.get('/', employeeController.getAllEmployees);
router.get('/:id', employeeController.getEmployeeById);
router.post('/', employeeController.createEmployee);
router.put('/:id', employeeController.updateEmployee);
router.delete('/:id', employeeController.deleteEmployee);

// Financials
router.post('/advance', employeeController.addAdvance);
router.post('/salary', employeeController.addSalaryPayment);
router.delete('/advance/:id', employeeController.deleteAdvance);
router.delete('/salary/:id', employeeController.deleteSalaryPayment);
router.post('/advance/bulk-delete', employeeController.deleteAllAdvances);
router.post('/salary/bulk-delete', employeeController.deleteAllSalaryPayments);

// Closures Actions
router.post('/closures', employeeController.addClosure);
router.delete('/closures/:period_ym', employeeController.deleteClosure);

module.exports = router;
