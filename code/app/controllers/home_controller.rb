require 'product_view_models'

class HomeController < ApplicationController
   #before_action :authenticate_user!
   before_action :authenticate_user!, :except => [:index, :test,:addSession,:BurgerProfile]

  def index

    # @cityDetected = request.location.city

    city_id = (params[:city_id].nil?) ? 1 : params[:city_id]
    @current_city = City.find_by_id(city_id)

    @cities = City.all
    # country = request.location.country_code

    @products = Product.get_products(city_id, 5)

    render layout: "home_layout"
  end

  def follow

    Follow.add(current_user.id, params[:friend_id])
    render :json => { :status => true }
  end

   def unfollow

     Follow.delete(current_user.id, params[:friend_id])
     render :json => { :status => true }
   end


  def search

    # @cityDetected = request.location.city

    @keyword = params[:keyword]
    @products = Product.search(@keyword)

    @myprofile = Profile.getProfile(current_user.id)

    render layout: "search_layout"
  end



  def userprofile

    ### friend
    @friend = User.find_by_id(params[:id])

    @isMyprofile = (@friend.id == current_user.id) ? true : false

    if @friend.nil?
      @friend = User.find_by_id(1)
    end

    @profile = Profile.getProfile(params[:id])
    limit = (params[:fulllist].nil?) ? 5 : 1000
    @products = @friend.get_products_reviewed(limit)

    ### user
    @user = current_user
    @myprofile = Profile.getProfile(current_user.id)
    @isFollowed = @user.isFollowed(@friend.id)

    # layout
    render layout: "userprofile_layout"
  end

   def upload_avatar
     @profile = Profile.find(params[:profile][:id])
     @profile.update(avatar: params[:profile][:avatar])
     redirect_to :controller => 'home', :action => 'userprofile', :id => current_user.id

   end



  def myprofile

    @user = current_user
    @myprofile = Profile.getProfile(current_user.id)
    @products = Product.all

    render layout: "myprofile_layout"
  end
  def AddComemnt
    if user_signed_in?
      if (!params[:content].blank?)

        if params[:file].present?
          Review.save(params[:file])

        end
        Comment.create(content:  params[:content],images: params[:file],product_id:params[:productid],user_id:current_user.id)
      end
    end
    redirect_to :controller => 'home', :action => 'BurgerProfile', :id => params[:productid]
  end
  def review_post
    # parsed_json = ActiveSupport::JSON.decode(params[:_json])

    # add review
    review = Review.add(current_user.id, params[:review][:product_id], params[:review][:totalpoint])

    # add review component
    params[:review_components].each do |component|
      ReviewComponent.add(review.id, component[:review_type_id], component[:point])
      # logger.debug component[:review_type_id].inspect
    end

    # add comment
    if (!params[:comment][:content].blank?)

      #name=params[:comment][:filename].original_filename
      #directory = "public/comment"
      # create the file path
      #path = File.join(directory, name)
      # write the file
      #File.open(path, "wb") { |f| f.write(params[:comment][:filename].read) }
      Commentproduct.add(review.id, params[:comment][:content],params[:comment][:namefile])
    end

    render :json => { :data => true }
  end
def uploadImgaes
  name=params[:file].original_filename
  directory = "public/comment"
  # create the file path
  path = File.join(directory, name)
  # write the file
  File.open(path, "wb") { |f| f.write(params[:file].read) }
  render :json => { :data => true }
end
  def review

    @myprofile = Profile.getProfile(current_user.id)
    @restaurant=Restaurant.all()

    @restaurant_product=Product.where(restaurant_id: @restaurant.first().id)
    if params[:product_id].present?
      @product = Product.find_by_id(params[:product_id])
      @isReviewed = @product.check_reviewed(current_user.id)
      if(@isReviewed)
        @reviewed = Review.getReviewed(current_user.id,  @product.id)
        @reviewed_components = @reviewed.get_reviewed_components()
      end
    else
      @product = Product.find_by_id(@restaurant_product.first().id)
      @isReviewed = @product.check_reviewed(current_user.id)
      if(@isReviewed)
        @reviewed = Review.getReviewed(current_user.id,  @product.id)
        @reviewed_components = @reviewed.get_reviewed_components()
      end
    end

    @review_type = ReviewType.get_all


    render layout: "review_layout"
  end
  def getchangeproduct
    @restaurant_product=Product.where(restaurant_id: params[:idre])
    render :json => { :data => @restaurant_product }
  end
  #hungnt
  #login
  def login

      @componant=Component.all
      #citycurrent = request.location.city
      #countrycrrent=request.location.country
      #if countrycrrent.nil?
        #countryid=Country.find_by_name(countrycrrent).id
      #else
        country=Country.all.order("name ASC")
        countryid=country.first().id
     # end
      @location=City.where(country_id:countryid)
      #@location=City.all
      if request.post?

        @city_id=params[:city_id]
        @city = City.find_by_id(@city_id)
        if @city.present?
            @data=Product.joins(:restaurant).select("products.id,products.images_file_name,products.name as productname,restaurants.name as restaurantsname").where(restaurants: {city_id: @city_id})
        else
          @kk=params[:idcomponennt]
          @icomponent=params[:idcomponennt].split(/;/)
          @data=Product.joins(:product_components).joins(:restaurant).select("products.id,products.images_file_name,products.name as productname,restaurants.name as restaurantsname").distinct.where(product_components:{component_value_id: @icomponent})
          @listvalue=ComponentValue.where(id: @icomponent)
            
        end



      else
        #if citycurrent.nil?
          #locationcureent=City.find_by_name(citycurrent)
          #@city_id=locationcureent.id
          #@city = City.find_by_id(@city_id)
         # @data=Product.joins(:restaurant).select("products.id,products.images_file_name,products.name as productname,restaurants.name as restaurantsname").where(restaurants: {city_id: @city_id})
        #else
          @data=Product.joins(:restaurant).select("products.id,products.images_file_name,products.name as productname,restaurants.name as restaurantsname").where(restaurants: {city_id: @location.first().id})
        #end
      end
      @profile=Profile.where(user_id: current_user.id).first()
      render layout: "homelogin/homelogin"
  end

  def geolocation
    # render layout: "homelogin"
    render :action => "index", layout: "geolocation"
  end

  #hungnt
  #BurgerProfile
  def BurgerProfile
        @avrage=Product.get_socre_average_product_byid(params[:id],1)
        @countreview=Product.get_score_product_groupByuserId(params[:id],999999)
        Product.update_views_product_byid(params[:id])
        @productdetails=Product.get_product_Byid(params[:id])
        @scoreuser=Product.get_score_product_groupByuserId(params[:id],3)
        if user_signed_in?
          @profile=Profile.where(user_id: current_user.id).first()
        end
        @comemntproduct=Comment.where(product_id: params[:id])

      render layout:"BurgerProfile/BurgerProfile"
  end
  #hungnt
  #locations
  def locations
    render layout:"locations/locations"
  end

  def test
    # render layout: "homelogin"
    # redirect_to home_index
    # redirect_to :controller => 'home', :action => 'login'
    render layout: "application"
  end

  def test_ajax
    render json: Restaurant.all
  end
  def getProductByCity
    logger.debug('here')
    @ok="111"

    render layout: "homelogin/homelogin"
  end
  def addSession
    session[:checklogin]=1
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: 1}
    end
  end

  def addlike
    logger.debug params[:id].inspect
      Commentproduct.updatelike(params[:id])
      render :json => { :status => true }
  end
  def actionSendMail
    _html="";
    _html+="<p>You just received an invitation from a friend . You can click  here</a> to see details:</p>"+request.host_with_port+params[:link];
    _html+="<p>"+params[:message]+"</p>";
    _email=""
    if user_signed_in?
      _email=User.where(id: current_user.id).first().email
    end
    mail = UserNotifier.send_mail_toshare(params[:email],"You just received an invitation from a friend",_html,_email)
    mail.deliver
    render :json => { :status => true }
  end


   private
  # Use callbacks to share common setup or constraints between actions.
   def set_profile
     @profile = Profile.find(params[:id])
   end

   # Never trust parameters from the scary internet, only allow the white list through.
   def profile_params
     params.require(:profile).permit(:id, :avatar)
   end
end
