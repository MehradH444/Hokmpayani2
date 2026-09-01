/**
 * Game Features & Economy Controller
 * File: gameController.js
 * Description: Handles Shop transactions, Leaderboards, Daily Rewards/Wheel, and Clan management APIs.
 */

const User = require('./User');
const ShopItem = require('./ShopItem');
const Clan = require('./Clan');

/**
 * @desc    دریافت لیست آیتم‌های فروشگاه
 * @route   GET /api/game/shop/items
 */
exports.getShopItems = async (req, res) => {
  try {
    const items = await ShopItem.find({ isActive: true });
    res.status(200).json({ success: true, count: items.length, data: items });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

/**
 * @desc    خرید آیتم از فروشگاه
 * @route   POST /api/game/shop/buy
 */
exports.buyShopItem = async (req, res) => {
  try {
    const { itemId } = req.body;
    const item = await ShopItem.findOne({ itemId, isActive: true });
    if (!item) {
      return res.status(404).json({ success: false, message: 'آیتم مورد نظر یافت نشد' });
    }

    const user = await User.findById(req.user.id);

    // بررسی موجودی در صورت پرداخت با سکه یا الماس درون برنامه‌ای
    if (item.price.currency === 'coins' && user.wallet.coins < item.price.amount) {
      return res.status(400).json({ success: false, message: 'موجودی سکه کافی نیست' });
    }
    if (item.price.currency === 'gems' && user.wallet.gems < item.price.amount) {
      return res.status(400).json({ success: false, message: 'موجودی الماس کافی نیست' });
    }

    // کسر هزینه
    if (item.price.currency === 'coins') user.wallet.coins -= item.price.amount;
    if (item.price.currency === 'gems') user.wallet.gems -= item.price.amount;

    // واریز پاداش خرید
    if (item.reward.coins > 0) user.wallet.coins += item.reward.coins;
    if (item.reward.gems > 0) user.wallet.gems += item.reward.gems;

    // ارتقای اکانت به VIP
    if (item.reward.vipDays > 0) {
      user.isVIP = true;
      const expiryDate = user.vipExpiresAt && user.vipExpiresAt > Date.now()
        ? new Date(user.vipExpiresAt.getTime() + item.reward.vipDays * 86400000)
        : new Date(Date.now() + item.reward.vipDays * 86400000);
      user.vipExpiresAt = expiryDate;
    }

    // فعال‌سازی پوسته یا تم خریداری شده
    if (item.category === 'card_skin') user.cardSkin = item.itemId;
    if (item.category === 'table_theme') user.tableTheme = item.itemId;

    await user.save();

    res.status(200).json({
      success: true,
      message: 'خرید با موفقیت انجام شد',
      wallet: user.wallet,
      cardSkin: user.cardSkin,
      tableTheme: user.tableTheme,
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

/**
 * @desc    دریافت جدول برترین بازیکنان (Leaderboard)
 * @route   GET /api/game/leaderboard
 */
exports.getLeaderboard = async (req, res) => {
  try {
    const topPlayers = await User.find({})
      .select('username avatar levelInfo stats.gamesWon stats.totalCoinsEarned wallet.coins')
      .sort({ 'stats.gamesWon': -1, 'wallet.coins': -1 })
      .limit(50);

    res.status(200).json({ success: true, count: topPlayers.length, data: topPlayers });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

/**
 * @desc    دریافت پاداش گردونه شانس روزانه
 * @route   POST /api/game/daily-reward
 */
exports.claimDailyReward = async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    const now = new Date();

    if (user.dailyRewardLastClaimed) {
      const hoursSinceLastClaim = (now - new Date(user.dailyRewardLastClaimed)) / (1000 * 60 * 60);
      if (hoursSinceLastClaim < 24) {
        return res.status(400).json({
          success: false,
          message: 'پاداش روزانه امروز دریافت شده است. زمان باقی‌مانده را منتظر بمانید.',
        });
      }
    }

    // محاسبه پاداش تصادفی گردونه (بین ۵۰۰ تا ۵۰۰۰ سکه)
    const rewardCoins = Math.floor(Math.random() * 10) * 500 + 500;
    user.wallet.coins += rewardCoins;
    user.dailyRewardLastClaimed = now;

    await user.save();

    res.status(200).json({
      success: true,
      rewardCoins,
      wallet: user.wallet,
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

/**
 * @desc    ساخت کلن جدید
 * @route   POST /api/game/clan/create
 */
exports.createClan = async (req, res) => {
  try {
    const { name, description, badge } = req.body;
    const user = await User.findById(req.user.id);

    if (user.clan.clanId) {
      return res.status(400).json({ success: false, message: 'شما در حال حاضر عضو یک کلن هستید' });
    }

    // هزینه ساخت کلن (مثلا ۵۰۰۰ سکه)
    const creationFee = 5000;
    if (user.wallet.coins < creationFee) {
      return res.status(400).json({ success: false, message: 'سکه کافی برای ساخت کلن ندارید' });
    }

    user.wallet.coins -= creationFee;

    const clan = await Clan.create({
      name,
      description,
      badge,
      leader: user._id,
    });

    user.clan = {
      clanId: clan._id,
      role: 'leader',
      joinedAt: Date.now(),
    };

    await user.save();

    res.status(201).json({ success: true, clan, wallet: user.wallet });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

/**
 * @desc    عضویت در کلن
 * @route   POST /api/game/clan/join
 */
exports.joinClan = async (req, res) => {
  try {
    const { clanId } = req.body;
    const user = await User.findById(req.user.id);

    if (user.clan.clanId) {
      return res.status(400).json({ success: false, message: 'ابتدا باید از کلن فعلی خود خارج شوید' });
    }

    const clan = await Clan.findById(clanId);
    if (!clan) {
      return res.status(404).json({ success: false, message: 'کلن یافت نشد' });
    }

    if (clan.membersCount >= clan.maxMembers) {
      return res.status(400).json({ success: false, message: 'ظرفیت این کلن تکمیل است' });
    }

    clan.membersCount += 1;
    await clan.save();

    user.clan = {
      clanId: clan._id,
      role: 'member',
      joinedAt: Date.now(),
    };
    await user.save();

    res.status(200).json({ success: true, message: 'با موفقیت عضو کلن شدید', clan });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
