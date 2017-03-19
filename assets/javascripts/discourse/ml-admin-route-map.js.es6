export default {
  resource: 'admin',
  map() {
    this.route('adminMl', { path: '/ml', resetNamespace: true }, function() {
      this.route('models', { path: '/models' });
      this.route('runs', { path: '/runs' });
      this.route('images', { path: '/images' });
      this.route('datasets', { path: '/datasets' });
    });
  }
};
