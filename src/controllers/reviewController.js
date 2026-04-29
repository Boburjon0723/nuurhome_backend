const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

exports.getProductReviews = async (req, res) => {
  const { productId } = req.params;
  try {
    const reviews = await prisma.review.findMany({
      where: { 
        product_id: productId,
        status: 'approved'
      },
      orderBy: { created_at: 'desc' }
    });
    res.json({ success: true, reviews });
  } catch (error) {
    console.error('Get Reviews Error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
};

exports.addReview = async (req, res) => {
  const { product_id, user_id, author_display_name, rating, comment, status } = req.body;
  try {
    const review = await prisma.review.create({
      data: {
        product_id,
        user_id,
        author_display_name,
        rating: parseInt(rating),
        comment,
        status: status || 'pending'
      }
    });
    res.json({ success: true, review });
  } catch (error) {
    console.error('Add Review Error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
};
