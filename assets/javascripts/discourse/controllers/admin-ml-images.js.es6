import showModal from 'discourse/lib/show-modal';

export default Ember.Controller.extend({
  images: Ember.A(),
  activeLabel: null,

  visibleImages: function() {
    return this.get('activeLabel') ?
           this.get('images').filter((i) => i.label === this.get('activeLabel')):
           this.get('images');
  }.property('images', 'activeLabel'),

  subscribeToImages: function() {
    let self = this;
    this.messageBus.subscribe('/admin/ml/images', function(response) {
      console.log(response)
      if (response.action === 'remove') {
        self.set('images', self.get('images').filter((i) =>
          i.name !== response.name
        ));
      }
    })
  }.on('init'),

  actions: {
    clearFilter() {
      this.set('activeLabel', null)
    }
  },
});
