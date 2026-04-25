const express = require('express');
const router = express.Router();
const colorController = require('../controllers/colorController');

router.get('/', colorController.getAllColors);
router.post('/', colorController.createColor);
router.delete('/:id', colorController.deleteColor);

module.exports = router;
