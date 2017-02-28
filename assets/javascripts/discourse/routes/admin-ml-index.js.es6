export default Discourse.Route.extend({
  redirect: function() {
    this.transitionTo('adminMl.models');
  }
});
