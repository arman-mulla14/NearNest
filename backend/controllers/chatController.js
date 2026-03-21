const Message = require('../models/Message');
const User = require('../models/User');

exports.sendMessage = async (req, res) => {
  try {
    const { receiverId, text } = req.body;
    const message = new Message({
      sender: req.user._id,
      receiver: receiverId,
      text
    });
    await message.save();
    res.status(201).json(message);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.getChatHistory = async (req, res) => {
  try {
    const { otherUserId } = req.params;
    const messages = await Message.find({
      $or: [
        { sender: req.user._id, receiver: otherUserId },
        { sender: otherUserId, receiver: req.user._id }
      ]
    }).sort({ createdAt: 1 });
    res.json(messages);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.getRecentChats = async (req, res) => {
  try {
    const userId = req.user._id;
    const messages = await Message.find({
      $or: [{ sender: userId }, { receiver: userId }]
    })
    .sort({ createdAt: -1 })
    .populate('sender', 'name email')
    .populate('receiver', 'name email');

    const chats = {};
    messages.forEach(msg => {
      const otherUser = msg.sender._id.toString() === userId.toString() ? msg.receiver : msg.sender;
      if (otherUser && !chats[otherUser._id]) {
        chats[otherUser._id] = {
          user: otherUser,
          lastMessage: msg.text,
          time: msg.createdAt
        };
      }
    });

    res.json(Object.values(chats));
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};
