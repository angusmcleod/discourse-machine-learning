export default Ember.Component.extend({
  tagName: 'div',

  trainFileName: function() {
    return this.getLinkPath(this.get('dataset.train_link'))
  }.property(),

  testFileName: function() {
    return this.getLinkPath(this.get('dataset.test_link'))
  }.property(),

  getLinkPath: function(link) {
    let linkArr = link.split('/');
    return linkArr[linkArr.length - 1];
  },

  actions: {
    destroy(dataset) {
      dataset.destroy();
    }
  }
});
