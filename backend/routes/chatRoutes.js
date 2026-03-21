const express = require('express');
const { sendMessage, getChatHistory, getRecentChats } = require('../controllers/chatController');
const { protect } = require('../middlewares/authMiddleware');
const router = express.Router();

router.post('/', protect, sendMessage);
router.get('/recent', protect, getRecentChats);
router.get('/:otherUserId', protect, getChatHistory);

module.exports = router;
