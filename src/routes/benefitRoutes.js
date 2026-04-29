const express = require('express');
const router = express.Router();
const benefitController = require('../controllers/benefitController');

router.get('/', benefitController.getAllBenefits);
router.post('/', benefitController.createBenefit);
router.put('/:id', benefitController.updateBenefit);
router.delete('/:id', benefitController.deleteBenefit);

module.exports = router;
