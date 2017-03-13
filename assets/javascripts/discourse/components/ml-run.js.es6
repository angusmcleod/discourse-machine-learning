import { ajax } from 'discourse/lib/ajax';

export default Ember.Component.extend({
  tagName: 'div',

  status: function() {
    return I18n.t(`ml.admin.run.status.${this.get('run.status')}`);
  }.property('run.status'),

  actions: {
    destroy(run) {
      run.destroy();
    }
  }
});
