const Property = require('../models/Property');

exports.getProperties = async (req, res) => {
  try {
    console.log('getProperties called');
    const { keyword, propertyType, maxPrice, vendor, page = 1, limit = 10 } = req.query;
    
    let query = {};
    if (keyword) {
      query.title = { $regex: keyword, $options: 'i' };
    }
    if (propertyType) {
      query.propertyType = propertyType;
    }
    if (maxPrice) {
      query.price = { $lte: Number(maxPrice) };
    }
    if (vendor) {
      query.vendor = vendor;
    }

    const pageNumber = parseInt(page, 10);
    const limitNumber = parseInt(limit, 10);
    const skip = (pageNumber - 1) * limitNumber;

    console.log('Executing DB query with:', query);
    const properties = await Property.find(query)
      .populate('vendor', 'name email')
      .select({ ratings: 0, images: { $slice: 1 } }) 
      .skip(skip)
      .limit(limitNumber)
      .lean();

    console.log('Query successful, returning properties:', properties.length);
    res.json(properties);
  } catch (error) {
    console.error('Error in getProperties:', error);
    res.status(500).json({ message: error.message });
  }
};

exports.getPropertyById = async (req, res) => {
  try {
    const property = await Property.findById(req.params.id).populate('vendor', 'name email');
    if (property) {
      res.json(property);
    } else {
      res.status(404).json({ message: 'Property not found' });
    }
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.createProperty = async (req, res) => {
  try {
    const { title, description, location, price, propertyType, images, facilities, availableBeds, availableTables } = req.body;
    
    const property = new Property({
      vendor: req.user._id,
      title,
      description,
      location,
      price,
      propertyType,
      images: images || [],
      facilities: facilities || [],
      availableBeds,
      availableTables,
      offer: req.body.offer || {}
    });

    const createdProperty = await property.save();
    res.status(201).json(createdProperty);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.updateProperty = async (req, res) => {
  try {
    const property = await Property.findById(req.params.id);

    if (property) {
      if (property.vendor.toString() !== req.user._id.toString()) {
        return res.status(401).json({ message: 'Not authorized to update this property' });
      }

      property.title = req.body.title || property.title;
      property.description = req.body.description || property.description;
      property.location = req.body.location || property.location;
      property.price = req.body.price || property.price;
      property.propertyType = req.body.propertyType || property.propertyType;
      property.images = req.body.images || property.images;
      property.facilities = req.body.facilities || property.facilities;
      property.availableBeds = req.body.availableBeds !== undefined ? req.body.availableBeds : property.availableBeds;
      property.availableTables = req.body.availableTables !== undefined ? req.body.availableTables : property.availableTables;
      if (req.body.offer) {
        property.offer = req.body.offer;
      }

      const updatedProperty = await property.save();
      res.json(updatedProperty);
    } else {
      res.status(404).json({ message: 'Property not found' });
    }
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.deleteProperty = async (req, res) => {
  try {
    const property = await Property.findById(req.params.id);

    if (property) {
      if (property.vendor.toString() !== req.user._id.toString()) {
        return res.status(401).json({ message: 'Not authorized to delete this property' });
      }
      await property.deleteOne();
      res.json({ message: 'Property removed' });
    } else {
      res.status(404).json({ message: 'Property not found' });
    }
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.addPropertyReview = async (req, res) => {
  try {
    const { rating, review, images } = req.body;
    const property = await Property.findById(req.params.id);

    if (property) {
      const alreadyReviewed = property.ratings.find(
        (r) => r.user.toString() === req.user._id.toString()
      );

      if (alreadyReviewed) {
        return res.status(400).json({ message: 'You have already reviewed this property' });
      }

      const reviewDoc = {
        name: req.user.name,
        rating: Number(rating),
        review,
        images: images || [],
        user: req.user._id,
      };

      property.ratings.push(reviewDoc);
      await property.save();
      res.status(201).json({ message: 'Review added' });
    } else {
      res.status(404).json({ message: 'Property not found' });
    }
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};
