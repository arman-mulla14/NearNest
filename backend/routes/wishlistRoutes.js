const express = require('express');
const router = express.Router();
const Wishlist = require('../models/Wishlist');
const { protect } = require('../middlewares/authMiddleware');

// @route   POST /api/wishlist
// @desc    Add property to wishlist
// @access  Private
router.post('/', protect, async (req, res) => {
  try {
    const { propertyId } = req.body;
    const wishlistItem = await Wishlist.create({
      user: req.user._id,
      property: propertyId
    });
    res.status(201).json(wishlistItem);
  } catch (error) {
    if (error.code === 11000) {
      return res.status(400).json({ message: 'Property already in wishlist' });
    }
    res.status(500).json({ message: 'Server Error' });
  }
});

// @route   GET /api/wishlist
// @desc    Get user wishlist
// @access  Private
router.get('/', protect, async (req, res) => {
  try {
    const wishlist = await Wishlist.find({ user: req.user._id }).populate('property');
    res.json(wishlist);
  } catch (error) {
    res.status(500).json({ message: 'Server Error' });
  }
});

// @route   DELETE /api/wishlist/:id
// @desc    Remove property from wishlist
// @access  Private
router.delete('/:id', protect, async (req, res) => {
  try {
    const wishlistItem = await Wishlist.findOne({
      user: req.user._id,
      property: req.params.id
    });
    
    if (!wishlistItem) {
      return res.status(404).json({ message: 'Wishlist item not found' });
    }
    
    await Wishlist.deleteOne({ _id: wishlistItem._id });
    res.json({ message: 'Removed from wishlist' });
  } catch (error) {
    res.status(500).json({ message: 'Server Error' });
  }
});

module.exports = router;
