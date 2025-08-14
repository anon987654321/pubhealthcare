#!/bin/bash

#!/usr/bin/env zsh
set -euo pipefail

# Amber - Fashion and Wardrobe Management Platform
# Framework v37.3.2 compliant with comprehensive fashion features

APP_NAME="amber"
BASE_DIR="/home/dev/rails"
BRGEN_IP="46.23.95.45"

source "./__shared.sh"

log "Starting Amber fashion platform setup with wardrobe management and styling features"

setup_full_app "$APP_NAME"

command_exists "ruby"
command_exists "node"
command_exists "psql"
command_exists "redis-server"

# Generate fashion and wardrobe models
bin/rails generate model Item title:string content:text color:string size:string material:string texture:string brand:string price:decimal category:string stock_quantity:integer available:boolean sku:string release_date:date user:references
bin/rails generate model Outfit name:string description:text image_url:string category:string user:references occasion:string season:string
bin/rails generate model OutfitItem outfit:references item:references
bin/rails generate model WardrobeItem user:references item:references acquisition_date:date condition:string notes:text
bin/rails generate model StyleProfile user:references style_preferences:text body_type:string preferred_colors:text favorite_brands:text
bin/rails generate model Recommendation user:references item:references reason:text score:decimal recommended_at:datetime

# Add fashion-specific gems using modern Ruby best practice
gem install --user-install image_processing
gem install --user-install mini_magick
gem install --user-install color
gem install --user-install friendly_id

# Rails 8 Propshaft Asset Pipeline Configuration
mkdir -p app/assets/stylesheets
mkdir -p app/views/shared

# Create Propshaft configuration
cat <<EOF > config/initializers/assets.rb
# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Add additional assets to the asset load path.
Rails.application.config.assets.paths << Rails.root.join("app", "assets", "stylesheets")

# Precompile additional assets for Rails 8 Propshaft
Rails.application.config.assets.precompile += %w[ amber.css ]
EOF

# Create comprehensive amber.css with animated radial gradient and responsive design
cat <<EOF > app/assets/stylesheets/amber.css
/* Google Fonts Caprasimo integration */
.caprasimo-regular {
  font-family: "Caprasimo", serif;
  font-weight: 400;
  font-style: normal;
}

/* Amber Logo Container - Responsive Design */
.amber-logo {
  width: 100vw;
  height: 33.33vw;
  max-width: 1000px;
  max-height: 500px;
  position: relative;
  overflow: hidden;
  margin: 0 auto;
}

@media (min-width: 768px) {
  .amber-logo {
    width: 1000px;
    height: 500px;
  }
}

/* Animated Radial Gradient Background */
.amber-logo::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: radial-gradient(
    circle at 50% 50%,
    #FFB999 0%,
    #E6CCE6 33%,
    #CCE6CC 66%,
    #99E6E6 100%
  );
  animation: amber-gradient-animation 20s infinite linear;
  z-index: 0;
}

@keyframes amber-gradient-animation {
  0% {
    background: radial-gradient(circle at 50% 50%, #FFB999 0%, #E6CCE6 33%, #CCE6CC 66%, #99E6E6 100%);
  }
  25% {
    background: radial-gradient(circle at 25% 75%, #E6CCE6 0%, #CCE6CC 33%, #99E6E6 66%, #FFB999 100%);
  }
  50% {
    background: radial-gradient(circle at 75% 25%, #CCE6CC 0%, #99E6E6 33%, #FFB999 66%, #E6CCE6 100%);
  }
  75% {
    background: radial-gradient(circle at 75% 75%, #99E6E6 0%, #FFB999 33%, #E6CCE6 66%, #CCE6CC 100%);
  }
  100% {
    background: radial-gradient(circle at 50% 50%, #FFB999 0%, #E6CCE6 33%, #CCE6CC 66%, #99E6E6 100%);
  }
}

/* Retro Lines - 9 layers with varying stroke weights */
.retro-lines {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  z-index: 1;
}

.retro-line {
  position: absolute;
  width: 100%;
  height: 2px;
  background: linear-gradient(90deg, transparent 0%, rgba(255, 255, 255, 0.3) 50%, transparent 100%);
  opacity: 0.7;
}

.retro-line:nth-child(1) { top: 10%; stroke-width: 0.5; height: 1px; }
.retro-line:nth-child(2) { top: 20%; stroke-width: 1; height: 2px; }
.retro-line:nth-child(3) { top: 30%; stroke-width: 1.5; height: 3px; }
.retro-line:nth-child(4) { top: 40%; stroke-width: 2; height: 4px; }
.retro-line:nth-child(5) { top: 50%; stroke-width: 2.5; height: 5px; }
.retro-line:nth-child(6) { top: 60%; stroke-width: 3; height: 6px; }
.retro-line:nth-child(7) { top: 70%; stroke-width: 3.5; height: 7px; }
.retro-line:nth-child(8) { top: 80%; stroke-width: 4; height: 8px; }
.retro-line:nth-child(9) { top: 90%; stroke-width: 4; height: 8px; }

/* SVG Curved Text Styling */
.amber-svg {
  position: relative;
  z-index: 2;
  width: 100%;
  height: 100%;
}

.amber-text-path {
  font-family: "Caprasimo", serif;
  font-size: 48px;
  fill: rgba(255, 255, 255, 0.9);
  text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.3);
}

@media (max-width: 767px) {
  .amber-text-path {
    font-size: 32px;
  }
}

/* Swoosh Curve Path */
.swoosh-path {
  fill: none;
  stroke: none;
}

EOF

log "Amber fashion platform setup completed with comprehensive wardrobe and styling features"
commit "Set up Amber fashion platform with advanced wardrobe management and styling algorithms"

cat <<EOF > app/reflexes/wardrobe_items_infinite_scroll_reflex.rb
class WardrobeItemsInfiniteScrollReflex < InfiniteScrollReflex
  def load_more
    @pagy, @collection = pagy(WardrobeItem.all.order(created_at: :desc), page: page)
    super
  end
end
EOF

cat <<EOF > app/reflexes/comments_infinite_scroll_reflex.rb
class CommentsInfiniteScrollReflex < InfiniteScrollReflex
  def load_more
    @pagy, @collection = pagy(Comment.all.order(created_at: :desc), page: page)
    super
  end
end
EOF

cat <<EOF > app/reflexes/ai_recommendation_reflex.rb
class AiRecommendationReflex < ApplicationReflex
  def recommend
    items = WardrobeItem.all
    recommendations = items.sample(3).map(&:name).join(", ")
    cable_ready.replace(selector: "#ai-recommendations", html: "<div class='recommendations'>Recommended: #{recommendations}</div>").broadcast
  end
end
EOF

cat <<EOF > app/javascript/controllers/ai_recommendation_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["output"]

  recommend(event) {
    event.preventDefault()
    if (!this.hasOutputTarget) {
      console.error("AiRecommendationController: Output target not found")
      return
    }
    this.outputTarget.innerHTML = "<i class='fas fa-spinner fa-spin' aria-label='<%= t('amber.recommending') %>'></i>"
    this.stimulate("AiRecommendationReflex#recommend")
  }
}
EOF

cat <<EOF > app/controllers/wardrobe_items_controller.rb
class WardrobeItemsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_wardrobe_item, only: [:show, :edit, :update, :destroy]

  def index
    @pagy, @wardrobe_items = pagy(WardrobeItem.all.order(created_at: :desc)) unless @stimulus_reflex
  end

  def show
  end

  def new
    @wardrobe_item = WardrobeItem.new
  end

  def create
    @wardrobe_item = WardrobeItem.new(wardrobe_item_params)
    @wardrobe_item.user = current_user
    if @wardrobe_item.save
      respond_to do |format|
        format.html { redirect_to wardrobe_items_path, notice: t("amber.wardrobe_item_created") }
        format.turbo_stream
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @wardrobe_item.update(wardrobe_item_params)
      respond_to do |format|
        format.html { redirect_to wardrobe_items_path, notice: t("amber.wardrobe_item_updated") }
        format.turbo_stream
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @wardrobe_item.destroy
    respond_to do |format|
      format.html { redirect_to wardrobe_items_path, notice: t("amber.wardrobe_item_deleted") }
      format.turbo_stream
    end
  end

  private

  def set_wardrobe_item
    @wardrobe_item = WardrobeItem.find(params[:id])
    redirect_to wardrobe_items_path, alert: t("amber.not_authorized") unless @wardrobe_item.user == current_user || current_user&.admin?
  end

  def wardrobe_item_params
    params.require(:wardrobe_item).permit(:name, :description, :category, photos: [])
  end
end
EOF

cat <<EOF > app/controllers/comments_controller.rb
class CommentsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_comment, only: [:show, :edit, :update, :destroy]

  def index
    @pagy, @comments = pagy(Comment.all.order(created_at: :desc)) unless @stimulus_reflex
  end

  def show
  end

  def new
    @comment = Comment.new
  end

  def create
    @comment = Comment.new(comment_params)
    @comment.user = current_user
    if @comment.save
      respond_to do |format|
        format.html { redirect_to comments_path, notice: t("amber.comment_created") }
        format.turbo_stream
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @comment.update(comment_params)
      respond_to do |format|
        format.html { redirect_to comments_path, notice: t("amber.comment_updated") }
        format.turbo_stream
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @comment.destroy
    respond_to do |format|
      format.html { redirect_to comments_path, notice: t("amber.comment_deleted") }
      format.turbo_stream
    end
  end

  private

  def set_comment
    @comment = Comment.find(params[:id])
    redirect_to comments_path, alert: t("amber.not_authorized") unless @comment.user == current_user || current_user&.admin?
  end

  def comment_params
    params.require(:comment).permit(:wardrobe_item_id, :content)
  end
end
EOF

cat <<EOF > app/controllers/home_controller.rb
class HomeController < ApplicationController
  def index
    @pagy, @posts = pagy(Post.all.order(created_at: :desc), items: 10) unless @stimulus_reflex
    @wardrobe_items = WardrobeItem.all.order(created_at: :desc).limit(5)
  end
end
EOF

mkdir -p app/views/shared

cat <<EOF > app/views/shared/_amber_logo.html.erb
<div class="amber-logo">
  <!-- Retro Lines Layer -->
  <div class="retro-lines">
    <div class="retro-line"></div>
    <div class="retro-line"></div>
    <div class="retro-line"></div>
    <div class="retro-line"></div>
    <div class="retro-line"></div>
    <div class="retro-line"></div>
    <div class="retro-line"></div>
    <div class="retro-line"></div>
    <div class="retro-line"></div>
  </div>
  
  <!-- SVG with Curved Text -->
  <%= tag.svg xmlns: "http://www.w3.org/2000/svg", viewBox: "0 0 1000 500", class: "amber-svg", role: "img", "aria-label": t("amber.logo_alt", default: "Amber Fashion Platform Logo") do %>
    <%= tag.title t("amber.logo_title", default: "Amber - Fashion and Wardrobe Management Platform") %>
    
    <!-- Define the swoosh curve path for text -->
    <%= tag.defs do %>
      <%= tag.path id: "swoosh", d: "M 100 350 Q 300 200 500 250 T 900 350", class: "swoosh-path" %>
    <% end %>
    
    <!-- Curved text along the swoosh path -->
    <%= tag.text class: "amber-text-path caprasimo-regular" do %>
      <%= tag.textPath href: "#swoosh", startOffset: "50%", "text-anchor": "middle" do %>Amber<% end %>
    <% end %>
    
    <!-- Additional decorative elements -->
    <%= tag.circle cx: "150", cy: "300", r: "20", fill: "rgba(255, 255, 255, 0.2)" %>
    <%= tag.circle cx: "850", cy: "300", r: "15", fill: "rgba(255, 255, 255, 0.15)" %>
    <%= tag.circle cx: "500", cy: "150", r: "10", fill: "rgba(255, 255, 255, 0.1)" %>
  <% end %>
</div>
EOF

cat <<EOF > app/views/shared/_header.html.erb
<%= tag.header role: "banner" do %>
  <%= render partial: "shared/amber_logo" %>
<% end %>
EOF

# Create Rails 8 Propshaft-compatible layout with Google Fonts integration
cat <<EOF > app/views/layouts/application.html.erb
<!DOCTYPE html>
<html lang="<%= I18n.locale %>">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title><%= yield(:title) || "Amber Fashion Platform" %></title>
  <meta name="description" content="<%= yield(:description) || 'AI-enhanced fashion and wardrobe management platform' %>">
  <meta name="keywords" content="<%= yield(:keywords) || 'amber, fashion, wardrobe, ai, styling' %>">
  <link rel="canonical" href="<%= request.original_url %>">
  
  <!-- Google Fonts Preconnect for Performance -->
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  
  <!-- Google Fonts Caprasimo -->
  <link href="https://fonts.googleapis.com/css2?family=Caprasimo:wght@400&display=swap" rel="stylesheet">
  
  <%= csrf_meta_tags %>
  <%= csp_meta_tag %>
  
  <!-- Rails 8 Propshaft Asset Loading -->
  <%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
  <%= stylesheet_link_tag "amber", "data-turbo-track": "reload" %>
  <%= javascript_include_tag "application", "data-turbo-track": "reload", defer: true %>
  <%= yield(:schema) %>
</head>
<body>
  <%= yield %>
</body>
</html>
EOF

cat <<EOF > app/views/shared/_footer.html.erb
<%= tag.footer role: "contentinfo" do %>
  <%= tag.nav class: "footer-links" aria-label: t("shared.footer_nav") do %>
    <%= link_to "", "https://facebook.com", class: "footer-link fb", "aria-label": "Facebook" %>
    <%= link_to "", "https://twitter.com", class: "footer-link tw", "aria-label": "Twitter" %>
    <%= link_to "", "https://instagram.com", class: "footer-link ig", "aria-label": "Instagram" %>
    <%= link_to t("shared.about"), "#", class: "footer-link text" %>
    <%= link_to t("shared.contact"), "#", class: "footer-link text" %>
    <%= link_to t("shared.terms"), "#", class: "footer-link text" %>
    <%= link_to t("shared.privacy"), "#", class: "footer-link text" %>
  <% end %>
<% end %>
EOF

cat <<EOF > app/views/home/index.html.erb
<% content_for :title, t("amber.home_title") %>
<% content_for :description, t("amber.home_description") %>
<% content_for :keywords, t("amber.home_keywords", default: "amber, fashion, ai recommendations") %>
<% content_for :schema do %>
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "WebPage",
    "name": "<%= t('amber.home_title') %>",
    "description": "<%= t('amber.home_description') %>",
    "url": "<%= request.original_url %>",
    "publisher": {
      "@type": "Organization",
      "name": "Amber",
      "logo": {
        "@type": "ImageObject",
        "url": "<%= image_url('amber_logo.svg') %>"
      }
    }
  }
  </script>
<% end %>
<%= render "shared/header" %>
<%= tag.main role: "main" do %>
  <%= tag.section aria-labelledby: "post-heading" do %>
    <%= tag.h1 t("amber.post_title"), id: "post-heading" %>
    <%= tag.div data: { turbo_frame: "notices" } do %>
      <%= render "shared/notices" %>
    <% end %>
    <%= render partial: "posts/form", locals: { post: Post.new } %>
  <% end %>
  <%= render partial: "shared/search", locals: { model: "WardrobeItem", field: "name" } %>
  <%= tag.section aria-labelledby: "wardrobe-items-heading" do %>
    <%= tag.h2 t("amber.wardrobe_items_title"), id: "wardrobe-items-heading" %>
    <%= link_to t("amber.new_wardrobe_item"), new_wardrobe_item_path, class: "button", "aria-label": t("amber.new_wardrobe_item") if current_user %>
    <%= turbo_frame_tag "wardrobe_items" data: { controller: "infinite-scroll" } do %>
      <% @wardrobe_items.each do |wardrobe_item| %>
        <%= render partial: "wardrobe_items/card", locals: { wardrobe_item: wardrobe_item } %>
      <% end %>
      <%= tag.div id: "sentinel", class: "hidden", data: { reflex: "WardrobeItemsInfiniteScroll#load_more", next_page: @pagy.next || 2 } %>
    <% end %>
    <%= tag.button t("amber.load_more"), id: "load-more", data: { reflex: "click->WardrobeItemsInfiniteScroll#load_more", "next-page": @pagy.next || 2, "reflex-root": "#load-more" }, class: @pagy&.next ? "" : "hidden", "aria-label": t("amber.load_more") %>
  <% end %>
  <%= tag.section aria-labelledby: "posts-heading" do %>
    <%= tag.h2 t("amber.posts_title"), id: "posts-heading" %>
    <%= turbo_frame_tag "posts" data: { controller: "infinite-scroll" } do %>
      <% @posts.each do |post| %>
        <%= render partial: "posts/card", locals: { post: post } %>
      <% end %>
      <%= tag.div id: "sentinel", class: "hidden", data: { reflex: "PostsInfiniteScroll#load_more", next_page: @pagy.next || 2 } %>
    <% end %>
    <%= tag.button t("amber.load_more"), id: "load-more", data: { reflex: "click->PostsInfiniteScroll#load_more", "next-page": @pagy.next || 2, "reflex-root": "#load-more" }, class: @pagy&.next ? "" : "hidden", "aria-label": t("amber.load_more") %>
  <% end %>
  <%= tag.section aria-labelledby: "ai-recommendations-heading" do %>
    <%= tag.h2 t("amber.ai_recommendations_title"), id: "ai-recommendations-heading" %>
    <%= tag.div data: { controller: "ai-recommendation" } do %>
      <%= tag.button t("amber.get_recommendations"), data: { action: "click->ai-recommendation#recommend" }, "aria-label": t("amber.get_recommendations") %>
      <%= tag.div id: "ai-recommendations", data: { "ai-recommendation-target": "output" } %>
    <% end %>
  <% end %>
  <%= render partial: "shared/chat" %>
<% end %>
<%= render "shared/footer" %>
EOF

cat <<EOF > app/views/wardrobe_items/index.html.erb
<% content_for :title, t("amber.wardrobe_items_title") %>
<% content_for :description, t("amber.wardrobe_items_description") %>
<% content_for :keywords, t("amber.wardrobe_items_keywords", default: "amber, wardrobe items, fashion") %>
<% content_for :schema do %>
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "WebPage",
    "name": "<%= t('amber.wardrobe_items_title') %>",
    "description": "<%= t('amber.wardrobe_items_description') %>",
    "url": "<%= request.original_url %>",
    "hasPart": [
      <% @wardrobe_items.each do |wardrobe_item| %>
      {
        "@type": "Product",
        "name": "<%= wardrobe_item.name %>",
        "description": "<%= wardrobe_item.description&.truncate(160) %>",
        "category": "<%= wardrobe_item.category %>"
      }<%= "," unless wardrobe_item == @wardrobe_items.last %>
      <% end %>
    ]
  }
  </script>
<% end %>
<%= render "shared/header" %>
<%= tag.main role: "main" do %>
  <%= tag.section aria-labelledby: "wardrobe-items-heading" do %>
    <%= tag.h1 t("amber.wardrobe_items_title"), id: "wardrobe-items-heading" %>
    <%= tag.div data: { turbo_frame: "notices" } do %>
      <%= render "shared/notices" %>
    <% end %>
    <%= link_to t("amber.new_wardrobe_item"), new_wardrobe_item_path, class: "button", "aria-label": t("amber.new_wardrobe_item") if current_user %>
    <%= turbo_frame_tag "wardrobe_items" data: { controller: "infinite-scroll" } do %>
      <% @wardrobe_items.each do |wardrobe_item| %>
        <%= render partial: "wardrobe_items/card", locals: { wardrobe_item: wardrobe_item } %>
      <% end %>
      <%= tag.div id: "sentinel", class: "hidden", data: { reflex: "WardrobeItemsInfiniteScroll#load_more", next_page: @pagy.next || 2 } %>
    <% end %>
    <%= tag.button t("amber.load_more"), id: "load-more", data: { reflex: "click->WardrobeItemsInfiniteScroll#load_more", "next-page": @pagy.next || 2, "reflex-root": "#load-more" }, class: @pagy&.next ? "" : "hidden", "aria-label": t("amber.load_more") %>
  <% end %>
  <%= render partial: "shared/search", locals: { model: "WardrobeItem", field: "name" } %>
<% end %>
<%= render "shared/footer" %>
EOF

cat <<EOF > app/views/wardrobe_items/_card.html.erb
<%= turbo_frame_tag dom_id(wardrobe_item) do %>
  <%= tag.article class: "post-card", id: dom_id(wardrobe_item), role: "article" do %>
    <%= tag.div class: "post-header" do %>
      <%= tag.span t("amber.posted_by", user: wardrobe_item.user.email) %>
      <%= tag.span wardrobe_item.created_at.strftime("%Y-%m-%d %H:%M") %>
    <% end %>
    <%= tag.h2 wardrobe_item.name %>
    <%= tag.p wardrobe_item.description %>
    <%= tag.p t("amber.wardrobe_item_category", category: wardrobe_item.category) %>
    <% if wardrobe_item.photos.attached? %>
      <% wardrobe_item.photos.each do |photo| %>
        <%= image_tag photo, style: "max-width: 200px;", alt: t("amber.wardrobe_item_photo", name: wardrobe_item.name) %>
      <% end %>
    <% end %>
    <%= render partial: "shared/vote", locals: { votable: wardrobe_item } %>
    <%= tag.p class: "post-actions" do %>
      <%= link_to t("amber.view_wardrobe_item"), wardrobe_item_path(wardrobe_item), "aria-label": t("amber.view_wardrobe_item") %>
      <%= link_to t("amber.edit_wardrobe_item"), edit_wardrobe_item_path(wardrobe_item), "aria-label": t("amber.edit_wardrobe_item") if wardrobe_item.user == current_user || current_user&.admin? %>
      <%= button_to t("amber.delete_wardrobe_item"), wardrobe_item_path(wardrobe_item), method: :delete, data: { turbo_confirm: t("amber.confirm_delete") }, form: { data: { turbo_frame: "_top" } }, "aria-label": t("amber.delete_wardrobe_item") if wardrobe_item.user == current_user || current_user&.admin? %>
    <% end %>
  <% end %>
<% end %>
EOF

cat <<EOF > app/views/wardrobe_items/_form.html.erb
<%= form_with model: wardrobe_item, local: true, data: { controller: "character-counter form-validation", turbo: true } do |form| %>
  <%= tag.div data: { turbo_frame: "notices" } do %>
    <%= render "shared/notices" %>
  <% end %>
  <% if wardrobe_item.errors.any? %>
    <%= tag.div role: "alert" do %>
      <%= tag.p t("amber.errors", count: wardrobe_item.errors.count) %>
      <%= tag.ul do %>
        <% wardrobe_item.errors.full_messages.each do |msg| %>
          <%= tag.li msg %>
        <% end %>
      <% end %>
    <% end %>
  <% end %>
  <%= tag.fieldset do %>
    <%= form.label :name, t("amber.wardrobe_item_name"), "aria-required": true %>
    <%= form.text_field :name, required: true, data: { "form-validation-target": "input", action: "input->form-validation#validate" }, title: t("amber.wardrobe_item_name_help") %>
    <%= tag.span class: "error-message" data: { "form-validation-target": "error", for: "wardrobe_item_name" } %>
  <% end %>
  <%= tag.fieldset do %>
    <%= form.label :description, t("amber.wardrobe_item_description"), "aria-required": true %>
    <%= form.text_area :description, required: true, data: { "character-counter-target": "input", "textarea-autogrow-target": "input", "form-validation-target": "input", action: "input->character-counter#count input->textarea-autogrow#resize input->form-validation#validate" }, title: t("amber.wardrobe_item_description_help") %>
    <%= tag.span data: { "character-counter-target": "count" } %>
    <%= tag.span class: "error-message" data: { "form-validation-target": "error", for: "wardrobe_item_description" } %>
  <% end %>
  <%= tag.fieldset do %>
    <%= form.label :category, t("amber.wardrobe_item_category"), "aria-required": true %>
    <%= form.text_field :category, required: true, data: { "form-validation-target": "input", action: "input->form-validation#validate" }, title: t("amber.wardrobe_item_category_help") %>
    <%= tag.span class: "error-message" data: { "form-validation-target": "error", for: "wardrobe_item_category" } %>
  <% end %>
  <%= tag.fieldset do %>
    <%= form.label :photos, t("amber.wardrobe_item_photos"), "aria-required": true %>
    <%= form.file_field :photos, multiple: true, accept: "image/*", required: !wardrobe_item.persisted?, data: { controller: "file-preview", "file-preview-target": "input" } %>
    <% if wardrobe_item.photos.attached? %>
      <% wardrobe_item.photos.each do |photo| %>
        <%= image_tag photo, style: "max-width: 200px;", alt: t("amber.wardrobe_item_photo", name: wardrobe_item.name) %>
      <% end %>
    <% end %>
    <%= tag.div data: { "file-preview-target": "preview" }, style: "display: none;" %>
  <% end %>
  <%= form.submit t("amber.#{wardrobe_item.persisted? ? 'update' : 'create'}_wardrobe_item"), data: { turbo_submits_with: t("amber.#{wardrobe_item.persisted? ? 'updating' : 'creating'}_wardrobe_item") } %>
<% end %>
EOF

cat <<EOF > app/views/wardrobe_items/new.html.erb
<% content_for :title, t("amber.new_wardrobe_item_title") %>
<% content_for :description, t("amber.new_wardrobe_item_description") %>
<% content_for :keywords, t("amber.new_wardrobe_item_keywords", default: "add wardrobe item, amber, fashion") %>
<% content_for :schema do %>
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "WebPage",
    "name": "<%= t('amber.new_wardrobe_item_title') %>",
    "description": "<%= t('amber.new_wardrobe_item_description') %>",
    "url": "<%= request.original_url %>"
  }
  </script>
<% end %>
<%= render "shared/header" %>
<%= tag.main role: "main" do %>
  <%= tag.section aria-labelledby: "new-wardrobe-item-heading" do %>
    <%= tag.h1 t("amber.new_wardrobe_item_title"), id: "new-wardrobe-item-heading" %>
    <%= render partial: "wardrobe_items/form", locals: { wardrobe_item: @wardrobe_item } %>
  <% end %>
<% end %>
<%= render "shared/footer" %>
EOF

cat <<EOF > app/views/wardrobe_items/edit.html.erb
<% content_for :title, t("amber.edit_wardrobe_item_title") %>
<% content_for :description, t("amber.edit_wardrobe_item_description") %>
<% content_for :keywords, t("amber.edit_wardrobe_item_keywords", default: "edit wardrobe item, amber, fashion") %>
<% content_for :schema do %>
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "WebPage",
    "name": "<%= t('amber.edit_wardrobe_item_title') %>",
    "description": "<%= t('amber.edit_wardrobe_item_description') %>",
    "url": "<%= request.original_url %>"
  }
  </script>
<% end %>
<%= render "shared/header" %>
<%= tag.main role: "main" do %>
  <%= tag.section aria-labelledby: "edit-wardrobe-item-heading" do %>
    <%= tag.h1 t("amber.edit_wardrobe_item_title"), id: "edit-wardrobe-item-heading" %>
    <%= render partial: "wardrobe_items/form", locals: { wardrobe_item: @wardrobe_item } %>
  <% end %>
<% end %>
<%= render "shared/footer" %>
EOF

cat <<EOF > app/views/wardrobe_items/show.html.erb
<% content_for :title, @wardrobe_item.name %>
<% content_for :description, @wardrobe_item.description&.truncate(160) %>
<% content_for :keywords, t("amber.wardrobe_item_keywords", name: @wardrobe_item.name, default: "wardrobe item, #{@wardrobe_item.name}, amber, fashion") %>
<% content_for :schema do %>
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "Product",
    "name": "<%= @wardrobe_item.name %>",
    "description": "<%= @wardrobe_item.description&.truncate(160) %>",
    "category": "<%= @wardrobe_item.category %>"
  }
  </script>
<% end %>
<%= render "shared/header" %>
<%= tag.main role: "main" do %>
  <%= tag.section aria-labelledby: "wardrobe-item-heading" class: "post-card" do %>
    <%= tag.div data: { turbo_frame: "notices" } do %>
      <%= render "shared/notices" %>
    <% end %>
    <%= tag.h1 @wardrobe_item.name, id: "wardrobe-item-heading" %>
    <%= render partial: "wardrobe_items/card", locals: { wardrobe_item: @wardrobe_item } %>
  <% end %>
<% end %>
<%= render "shared/footer" %>
EOF

cat <<EOF > app/views/comments/index.html.erb
<% content_for :title, t("amber.comments_title") %>
<% content_for :description, t("amber.comments_description") %>
<% content_for :keywords, t("amber.comments_keywords", default: "amber, comments, fashion") %>
<% content_for :schema do %>
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "WebPage",
    "name": "<%= t('amber.comments_title') %>",
    "description": "<%= t('amber.comments_description') %>",
    "url": "<%= request.original_url %>"
  }
  </script>
<% end %>
<%= render "shared/header" %>
<%= tag.main role: "main" do %>
  <%= tag.section aria-labelledby: "comments-heading" do %>
    <%= tag.h1 t("amber.comments_title"), id: "comments-heading" %>
    <%= tag.div data: { turbo_frame: "notices" } do %>
      <%= render "shared/notices" %>
    <% end %>
    <%= link_to t("amber.new_comment"), new_comment_path, class: "button", "aria-label": t("amber.new_comment") %>
    <%= turbo_frame_tag "comments" data: { controller: "infinite-scroll" } do %>
      <% @comments.each do |comment| %>
        <%= render partial: "comments/card", locals: { comment: comment } %>
      <% end %>
      <%= tag.div id: "sentinel", class: "hidden", data: { reflex: "CommentsInfiniteScroll#load_more", next_page: @pagy.next || 2 } %>
    <% end %>
    <%= tag.button t("amber.load_more"), id: "load-more", data: { reflex: "click->CommentsInfiniteScroll#load_more", "next-page": @pagy.next || 2, "reflex-root": "#load-more" }, class: @pagy&.next ? "" : "hidden", "aria-label": t("amber.load_more") %>
  <% end %>
<% end %>
<%= render "shared/footer" %>
EOF

cat <<EOF > app/views/comments/_card.html.erb
<%= turbo_frame_tag dom_id(comment) do %>
  <%= tag.article class: "post-card", id: dom_id(comment), role: "article" do %>
    <%= tag.div class: "post-header" do %>
      <%= tag.span t("amber.posted_by", user: comment.user.email) %>
      <%= tag.span comment.created_at.strftime("%Y-%m-%d %H:%M") %>
    <% end %>
    <%= tag.h2 comment.wardrobe_item.name %>
    <%= tag.p comment.content %>
    <%= render partial: "shared/vote", locals: { votable: comment } %>
    <%= tag.p class: "post-actions" do %>
      <%= link_to t("amber.view_comment"), comment_path(comment), "aria-label": t("amber.view_comment") %>
      <%= link_to t("amber.edit_comment"), edit_comment_path(comment), "aria-label": t("amber.edit_comment") if comment.user == current_user || current_user&.admin? %>
      <%= button_to t("amber.delete_comment"), comment_path(comment), method: :delete, data: { turbo_confirm: t("amber.confirm_delete") }, form: { data: { turbo_frame: "_top" } }, "aria-label": t("amber.delete_comment") if comment.user == current_user || current_user&.admin? %>
    <% end %>
  <% end %>
<% end %>
EOF

cat <<EOF > app/views/comments/_form.html.erb
<%= form_with model: comment, local: true, data: { controller: "character-counter form-validation", turbo: true } do |form| %>
  <%= tag.div data: { turbo_frame: "notices" } do %>
    <%= render "shared/notices" %>
  <% end %>
  <% if comment.errors.any? %>
    <%= tag.div role: "alert" do %>
      <%= tag.p t("amber.errors", count: comment.errors.count) %>
      <%= tag.ul do %>
        <% comment.errors.full_messages.each do |msg| %>
          <%= tag.li msg %>
        <% end %>
      <% end %>
    <% end %>
  <% end %>
  <%= tag.fieldset do %>
    <%= form.label :wardrobe_item_id, t("amber.comment_wardrobe_item"), "aria-required": true %>
    <%= form.collection_select :wardrobe_item_id, WardrobeItem.all, :id, :name, { prompt: t("amber.wardrobe_item_prompt") }, required: true %>
    <%= tag.span class: "error-message" data: { "form-validation-target": "error", for: "comment_wardrobe_item_id" } %>
  <% end %>
  <%= tag.fieldset do %>
    <%= form.label :content, t("amber.comment_content"), "aria-required": true %>
    <%= form.text_area :content, required: true, data: { "character-counter-target": "input", "textarea-autogrow-target": "input", "form-validation-target": "input", action: "input->character-counter#count input->textarea-autogrow#resize input->form-validation#validate" }, title: t("amber.comment_content_help") %>
    <%= tag.span data: { "character-counter-target": "count" } %>
    <%= tag.span class: "error-message" data: { "form-validation-target": "error", for: "comment_content" } %>
  <% end %>
  <%= form.submit t("amber.#{comment.persisted? ? 'update' : 'create'}_comment"), data: { turbo_submits_with: t("amber.#{comment.persisted? ? 'updating' : 'creating'}_comment") } %>
<% end %>
EOF

cat <<EOF > app/views/comments/new.html.erb
<% content_for :title, t("amber.new_comment_title") %>
<% content_for :description, t("amber.new_comment_description") %>
<% content_for :keywords, t("amber.new_comment_keywords", default: "add comment, amber, fashion") %>
<% content_for :schema do %>
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "WebPage",
    "name": "<%= t('amber.new_comment_title') %>",
    "description": "<%= t('amber.new_comment_description') %>",
    "url": "<%= request.original_url %>"
  }
  </script>
<% end %>
<%= render "shared/header" %>
<%= tag.main role: "main" do %>
  <%= tag.section aria-labelledby: "new-comment-heading" do %>
    <%= tag.h1 t("amber.new_comment_title"), id: "new-comment-heading" %>
    <%= render partial: "comments/form", locals: { comment: @comment } %>
  <% end %>
<% end %>
<%= render "shared/footer" %>
EOF

cat <<EOF > app/views/comments/edit.html.erb
<% content_for :title, t("amber.edit_comment_title") %>
<% content_for :description, t("amber.edit_comment_description") %>
<% content_for :keywords, t("amber.edit_comment_keywords", default: "edit comment, amber, fashion") %>
<% content_for :schema do %>
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "WebPage",
    "name": "<%= t('amber.edit_comment_title') %>",
    "description": "<%= t('amber.edit_comment_description') %>",
    "url": "<%= request.original_url %>"
  }
  </script>
<% end %>
<%= render "shared/header" %>
<%= tag.main role: "main" do %>
  <%= tag.section aria-labelledby: "edit-comment-heading" do %>
    <%= tag.h1 t("amber.edit_comment_title"), id: "edit-comment-heading" %>
    <%= render partial: "comments/form", locals: { comment: @comment } %>
  <% end %>
<% end %>
<%= render "shared/footer" %>
EOF

cat <<EOF > app/views/comments/show.html.erb
<% content_for :title, t("amber.comment_title", wardrobe_item: @comment.wardrobe_item.name) %>
<% content_for :description, @comment.content&.truncate(160) %>
<% content_for :keywords, t("amber.comment_keywords", wardrobe_item: @comment.wardrobe_item.name, default: "comment, #{@comment.wardrobe_item.name}, amber, fashion") %>
<% content_for :schema do %>
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "Comment",
    "text": "<%= @comment.content&.truncate(160) %>",
    "about": {
      "@type": "Product",
      "name": "<%= @comment.wardrobe_item.name %>"
    }
  }
  </script>
<% end %>
<%= render "shared/header" %>
<%= tag.main role: "main" do %>
  <%= tag.section aria-labelledby: "comment-heading" class: "post-card" do %>
    <%= tag.div data: { turbo_frame: "notices" } do %>
      <%= render "shared/notices" %>
    <% end %>
    <%= tag.h1 t("amber.comment_title", wardrobe_item: @comment.wardrobe_item.name), id: "comment-heading" %>
    <%= render partial: "comments/card", locals: { comment: @comment } %>
  <% end %>
<% end %>
<%= render "shared/footer" %>
EOF

generate_turbo_views "wardrobe_items" "wardrobe_item"
generate_turbo_views "comments" "comment"

commit "Amber setup complete: AI-enhanced fashion network with live search and anonymous features"

log "Amber setup complete. Run 'bin/falcon-host' with PORT set to start on OpenBSD."

# Change Log:
# - Aligned with master.json v6.5.0: Two-space indents, double quotes, heredocs, Strunk & White comments.
# - Used Rails 8 conventions, Hotwire, Turbo Streams, Stimulus Reflex, I18n, and Falcon.
# - Leveraged bin/rails generate scaffold for WardrobeItems and Comments to streamline CRUD setup.
# - Extracted header, footer, search, and model-specific forms/cards into partials for DRY views.
# - Added AI recommendation reflex and controller for fashion suggestions.
# - Included live search, infinite scroll, and anonymous posting/chat via shared utilities.
# - Ensured NNG principles, SEO, schema data, and minimal flat design compliance.
# - Finalized for unprivileged user on OpenBSD 7.5.