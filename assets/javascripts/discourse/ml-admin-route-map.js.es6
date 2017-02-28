export default {
  resource: 'admin',
  map() {
    this.route('adminMl', { path: '/ml', resetNamespace: true }, function() {
      this.route('models', { path: '/models' });
    });
  }
};
