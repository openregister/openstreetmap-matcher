target:
	rake clobber && rake package && gem install --local pkg/openstreetmap-matcher-*.gem
