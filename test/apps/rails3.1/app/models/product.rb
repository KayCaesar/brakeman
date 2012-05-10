class Product < ActiveRecord::Base
  def test_find_order
    #Should warn, no escaping done for :order
    Product.find(:all, :order => params[:order])
    Product.find(:all, :conditions => 'admin = 1', :order => "name #{params[:order]}")
  end

  def test_find_group
    #Should warn, no escaping done for :group
    Product.find(:all, :conditions => 'admin = 1', :group => params[:group])
    Product.find(:all, :conditions => 'admin = 1', :group => "something, #{params[:group]}")
  end

  def test_find_having
    #Should warn
    Product.find(:first, :conditions => 'admin = 1', :having => "x = #{params[:having]}")

    #Should not warn, hash values are escaped
    Product.find(:first, :conditions => 'admin = 1', :having => { :x => params[:having]})

    #Should not warn, properly interpolated
    Product.find(:first, :conditions => ['name = ?', params[:name]], :having => [ 'x = ?', params[:having]])

    #Should warn, not quite properly interpolated
    Product.find(:first, :conditions => ['name = ?', params[:name]], :having => [ "admin = ? and x = #{params[:having]}", cookies[:admin]])
    Product.find(:first, :conditions => ['name = ?', params[:name]], :having => [ "admin = ? and x = '" + params[:having] + "'", cookies[:admin]])
  end

  def test_find_joins
    #Should not warn, string values are not going to have injection
    Product.find(:first, :conditions => 'admin = 1', :joins => "LEFT JOIN comments ON comments.post_id = id")

    #Should warn
    Product.find(:first, :conditions => 'admin = 1', :joins => "LEFT JOIN comments ON comments.#{params[:join]} = id")

    #Should not warn
    Product.find(:first, :conditions => 'admin = 1', :joins => [:x, :y])

    #Should warn
    Product.find(:first, :conditions => 'admin = 1', :joins => ["LEFT JOIN comments ON comments.#{params[:join]} = id", :x, :y])
  end

  def test_find_select
    #Should not warn, string values are not going to have injection
    Product.find(:last, :conditions => 'admin = 1', :select => "name")

    #Should warn
    Product.find(:last, :conditions => 'admin = 1', :select => params[:column])
    Product.find(:last, :conditions => 'admin = 1', :select => "name, #{params[:column]}")
    Product.find(:last, :conditions => 'admin = 1', :select => "name, " + params[:column])
  end

  def test_find_from
    #Should not warn, string values are not going to have injection
    Product.find(:last, :conditions => 'admin = 1', :from => "users")

    #Should warn
    Product.find(:last, :conditions => 'admin = 1', :from => params[:table])
    Product.find(:last, :conditions => 'admin = 1', :from => "#{params[:table]}")
  end

  def test_find_lock
    #Should not warn
    Product.find(:last, :conditions => 'admin = 1', :lock => true)

    #Should warn
    Product.find(:last, :conditions => 'admin = 1', :lock => params[:lock])
    Product.find(:last, :conditions => 'admin = 1', :lock => "LOCK #{params[:lock]}")
  end

  def test_where
    #Should not warn
    Product.where("admin = 1")
    Product.where("admin = ?", params[:admin])
    Product.where(["admin = ?", params[:admin]])
    Product.where(["admin = :admin", { :admin => params[:admin] }])
    Product.where(:admin => params[:admin])

    #Should warn
    Product.where("admin = '#{params[:admin]}'").first
    Product.where(["admin = ? AND user_name = #{@name}", params[:admin]])
  end

  TOTALLY_SAFE = "some safe string"

  def test_constant_interpolation
    #Should not warn
    Product.first("blah = #{TOTALLY_SAFE}")
  end

  def test_local_interpolation
    #Should warn, medium confidence
    Product.first("blah = #{local_var}")
  end
end
