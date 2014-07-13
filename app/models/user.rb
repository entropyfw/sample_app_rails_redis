class User < ActiveRecord::Base
  attr_accessible :name, :email, :password, :password_confirmation
  has_secure_password
  has_many :microposts, dependent: :destroy
  has_many :relationships, foreign_key: "follower_id", dependent: :destroy
  has_many :followed_users, through: :relationships, source: :followed
  has_many :reverse_relationships, foreign_key: "followed_id",
                                   class_name: "Relationship",
                                   dependent: :destroy
  has_many :followers, through: :reverse_relationships, source: :follower

  before_save { |user| user.email = user.email.downcase }
  before_save :create_remember_token

  validates :name,  presence: true, length: { maximum: 50 }
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, presence: true, format: { with: VALID_EMAIL_REGEX },
                    uniqueness: { case_sensitive: false }
  validates :password, length: { minimum: 6 }
  validates :password_confirmation, presence: true

  def following?(other_user)
    $redis.sismember(self.redis_key(:following), other_user.id)
  end

  def following_count
    $redis.scard(self.redis_key(:following))
  end

  def follow!(other_user)
    $redis.multi do
      $redis.sadd(self.redis_key(:following), other_user.id)
      $redis.sadd(other_user.redis_key(:followers), self.id)
    end
  end

  def unfollow!(other_user)
    $redis.multi do
      $redis.srem(self.redis_key(:following), other_user.id)
      $redis.srem(user.redis_key(:followers), self.id)
    end
  end

  def followers_count
    $redis.scard(self.redis_key(:followers))
  end

  def followers
    user_ids = $redis.smembers(self.redis_key(:followers))
    User.where(:id => user_ids)
  end

  def feed
    Micropost.from_users_followed_by(self)
  end

  def redis_key(str)
    "user:#{self.id}:#{str}"
  end

  private

    def create_remember_token
      self.remember_token = SecureRandom.urlsafe_base64
    end
end
