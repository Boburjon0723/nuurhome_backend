const express = require('express');
const router = express.Router();
const messageController = require('../controllers/messageController');

router.post('/', messageController.createMessage);
router.get('/', messageController.getAllMessages);
router.patch('/:id/status', messageController.updateMessageStatus);
router.delete('/:id', messageController.deleteMessage);

module.exports = router;
