const Booking = require('../models/Booking');
const Property = require('../models/Property');
const Message = require('../models/Message');

exports.createBooking = async (req, res) => {
  try {
    const { propertyId, vendorId, checkInDate, checkOutDate, totalPrice } = req.body;
    
    const property = await Property.findById(propertyId);
    if (!property) return res.status(404).json({ message: 'Property not found' });
    
    const actualVendorId = vendorId || property.vendor;

    const booking = new Booking({
      property: propertyId,
      user: req.user._id,
      vendor: actualVendorId,
      checkInDate,
      checkOutDate,
      totalPrice
    });
    const createdBooking = await booking.save();

    // Auto-generate a chat message from user to vendor about the booking
    try {
      const autoMessage = new Message({
        sender: req.user._id,
        receiver: actualVendorId,
        text: `Hello! I would like to book your property "${property.title}" from ${new Date(checkInDate).toLocaleDateString()} to ${new Date(checkOutDate).toLocaleDateString()}. Please check your Bookings Dashboard to review my request!`
      });
      await autoMessage.save();
    } catch (msgErr) {
      console.log('Automated booking message failed to send:', msgErr);
    }

    res.status(201).json(createdBooking);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.getVendorBookings = async (req, res) => {
  try {
    const bookings = await Booking.find({ vendor: req.user._id })
      .populate('property')
      .populate('user', 'name email location');
    res.json(bookings);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.getUserBookings = async (req, res) => {
  try {
    const bookings = await Booking.find({ user: req.user._id }).populate('property').populate('vendor', 'name email');
    res.json(bookings);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.updateBookingStatus = async (req, res) => {
  try {
    const { status } = req.body;
    const booking = await Booking.findById(req.params.id);
    if (!booking) return res.status(404).json({ message: 'Booking not found' });
    
    if (booking.vendor.toString() !== req.user._id.toString()) {
      return res.status(401).json({ message: 'Not authorized' });
    }
    
    if (status === 'accepted' && booking.status !== 'accepted') {
      const property = await Property.findById(booking.property);
      if (property) {
        if (property.propertyType !== 'Restaurant') {
          if (property.availableBeds > 0) {
            property.availableBeds -= 1;
            // Mark that we decremented it on this booking to allow safe restore
            booking.bedsDecremented = true; 
          }
        }
        await property.save();
      }
    }
    // Optional defensive logic if a vendor somehow cancels an accepted booking
    else if (status !== 'accepted' && booking.status === 'accepted') {
      const property = await Property.findById(booking.property);
      if (property && booking.bedsDecremented) {
        property.availableBeds += 1;
        booking.bedsDecremented = false;
        await property.save();
      } else if (property && property.propertyType !== 'Restaurant' && property.availableBeds >= 0 && typeof booking.bedsDecremented === 'undefined') {
        // Fallback if bedsDecremented wasn't tracked previously
        property.availableBeds += 1;
        await property.save();
      }
    }

    booking.status = status;
    const updatedBooking = await booking.save();
    res.json(updatedBooking);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};
