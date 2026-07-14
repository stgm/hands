require "test_helper"

class EmbedScriptTest < ActionDispatch::IntegrationTest
    test "serves the widget loader as public javascript, no auth needed" do
        get embed_widget_script_path
        assert_response :success
        assert_match %r{javascript}, response.media_type
        assert_match "window.HandsEmbed", response.body
        assert_match "WidgetChannel", response.body
        assert_no_match(/Authorization.*secret/i, response.body) # no secret in the script
    end

    test "serves the widget stylesheet as public css" do
        get embed_widget_style_path
        assert_response :success
        assert_match %r{text/css}, response.media_type
        assert_match ".hands-widget", response.body
        assert_match "#ffc107", response.body # the signature yellow button colour
    end
end
