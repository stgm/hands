class Admin::BaseController < ApplicationController
    before_action :authorize
    before_action :require_admin
end
