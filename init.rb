ActionView::Base.send(:include, WebmoneyAcceptor::ViewExtension)
ActionController::Base.send(:include, WebmoneyAcceptor::ControllerExtension)