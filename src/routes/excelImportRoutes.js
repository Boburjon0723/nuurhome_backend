const express = require('express');
const router = express.Router();
const excelImportController = require('../controllers/excelImportController');

router.get('/history', excelImportController.getAllImports);
router.post('/save', excelImportController.saveImport);
router.delete('/:id', excelImportController.deleteImport);

module.exports = router;
