import { ajax } from 'discourse/lib/ajax';

export default Ember.Component.extend({
  tagName: 'div',
  built: Ember.computed.gt('image.status', 2),

  statusLabel: function() {
    return I18n.t(`ml.admin.image.status.${this.get('image.status')}`);
  }.property('image.status'),

  actions: {
    buildImage(image) {
      image.build();
    },

    removeImage(image) {
      image.remove();
    },

  }
});
