class HomeController < ApplicationController
    def index
        @domains = logged_in? ? current_user.course_domains.order(:name) : CourseDomain.none
    end
end
