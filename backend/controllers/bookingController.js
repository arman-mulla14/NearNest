const Booking = require('../models/Booking');
const Property = require('../models/Property');

exports.createBooking = async (req, res) => {
  try {
    const { propertyId, vendorId, checkInDate, checkOutDate, totalPrice } = req.body;
    const booking = new Booking({
      property: propertyId,
      user: req.user._id,
      vendor: vendorId,
      checkInDate,
      checkOutDate,
      totalPrice
    });
    const createdBooking = await booking.save();
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
        if (property.availableBeds > 0) {
          property.availableBeds -= 1;
          await property.save();
        } else {
          return res.status(400).json({ message: 'No available beds left to accept this booking.' });
        }
      }
    }
    // Optional defensive logic if a vendor somehow cancels an accepted booking
    else if (status !== 'accepted' && booking.status === 'accepted') {
      const property = await Property.findById(booking.property);
      if (property) {
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
