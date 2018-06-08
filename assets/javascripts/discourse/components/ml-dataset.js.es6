export default Ember.Component.extend({
  tagName: 'div',

  actions: {
    destroy(dataset) {
      dataset.destroy();
    }
  }
});
