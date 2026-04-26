const express = require('express');
const router = express.Router();
const financeController = require('../controllers/financeController');

// Departments
router.get('/departments', financeController.getDepartments);
router.post('/departments', financeController.createDepartment);
router.put('/departments/:id', financeController.updateDepartment);

// Partners
router.get('/partners', financeController.getPartners);
router.post('/partners', financeController.createPartner);

// Partner Entries
router.get('/partner-entries', financeController.getPartnerEntries);
router.post('/partner-entries', financeController.createPartnerEntry);
router.delete('/partner-entries/:id', financeController.deletePartnerEntry);

// Material Movements (Expenses)
router.get('/material-movements', financeController.getMaterialMovements);
router.post('/material-movements', financeController.createMaterialMovement);

// Payroll
router.get('/payouts', financeController.getPayouts);

module.exports = router;
