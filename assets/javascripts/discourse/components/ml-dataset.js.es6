export default Ember.Component.extend({
  tagName: 'tr',

  actions: {
    destroy(dataset) {
      dataset.destroy();
    }
  }
});
