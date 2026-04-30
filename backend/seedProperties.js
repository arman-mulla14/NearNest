const mongoose = require('mongoose');
const Property = require('./models/Property');
const User = require('./models/User');
const bcrypt = require('bcryptjs');
require('dotenv').config();

const seed = async () => {
  await mongoose.connect(process.env.MONGO_URI);
  console.log('MongoDB Connected');

  // Create a vendor
  let vendor = await User.findOne({ email: 'vendor@nearnest.com' });
  if (!vendor) {
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash('password123', salt);
    vendor = await User.create({
      name: 'Premium Vendor',
      email: 'vendor@nearnest.com',
      password: hashedPassword,
      role: 'Vendor'
    });
    console.log('Vendor created');
  }

  // Create a test user
  let testUser = await User.findOne({ email: 'i@gmail.com' });
  if (!testUser) {
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash('i@gmail.com', salt);
    testUser = await User.create({
      name: 'Tester User',
      email: 'i@gmail.com',
      password: hashedPassword,
      role: 'User'
    });
    console.log('Test user created');
  }

  const properties = [
    {
      vendor: vendor._id,
      title: 'Luxury Villa with Pool',
      description: 'A stunning luxury villa featuring a private pool and modern amenities.',
      location: 'Metropolis Heights, Sector 5',
      lat: 18.5204 + 0.01,
      lng: 73.8567 + 0.01,
      price: 2500,
      propertyType: 'PG',
      images: ['https://images.unsplash.com/photo-1512917774080-9991f1c4c750?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80'],
      facilities: ['Pool', 'WiFi', 'Parking', 'AC'],
      availableBeds: 5
    },
    {
      vendor: vendor._id,
      title: 'Modern City Apartment',
      description: 'Comfortable apartment located in the heart of the city.',
      location: 'Downtown Square, Metropolis',
      lat: 18.5204 - 0.01,
      lng: 73.8567 - 0.01,
      price: 1200,
      propertyType: 'Room',
      images: ['https://images.unsplash.com/photo-1560518883-ce09059eeffa?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80'],
      facilities: ['Gym', 'WiFi', 'Elevator'],
      availableBeds: 2
    },
    {
        vendor: vendor._id,
        title: 'Cozy Shared Lodge',
        description: 'Budget friendly shared lodge for travelers.',
        location: 'Old Town, Metropolis',
        lat: 18.5204,
        lng: 73.8567 + 0.02,
        price: 450,
        propertyType: 'Lodge',
        images: ['https://images.unsplash.com/photo-1555854811-8221a7eaa105?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80'],
        facilities: ['Common Kitchen', 'WiFi'],
        availableBeds: 10
      }
  ];

  await Property.deleteMany();
  await Property.insertMany(properties);
  console.log('Properties seeded successfully');
  process.exit();
};

seed().catch(err => {
  console.error(err);
  process.exit(1);
});
