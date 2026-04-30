const mongoose = require('mongoose');
const Property = require('./models/Property');
const Booking = require('./models/Booking');
const Wishlist = require('./models/Wishlist');
const Message = require('./models/Message');
const User = require('./models/User');
require('dotenv').config();

const clearData = async () => {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log('MongoDB Connected for cleanup...');

    // We might want to keep users but clear their data, 
    // or clear everything except the test accounts if needed.
    // The user said "remove all past data".
    
    await Property.deleteMany({});
    await Booking.deleteMany({});
    await Wishlist.deleteMany({});
    await Message.deleteMany({});
    
    // Optionally delete users who are not 'admin' if any
    // await User.deleteMany({ role: { $ne: 'Admin' } });

    console.log('Successfully removed all properties, bookings, wishlist items, and chats.');
    process.exit(0);
  } catch (err) {
    console.error('Cleanup Error:', err);
    process.exit(1);
  }
};

clearData();
