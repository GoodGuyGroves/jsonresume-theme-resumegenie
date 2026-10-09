const fs = require('fs');
const handlebars = require('handlebars');
const handlebarsWax = require('handlebars-wax');
const moment = require('moment');

handlebars.registerHelper({
  removeProtocol: url => url.replace(/.*?:\/\//g, ''),
  concat: (...args) => args.filter(arg => typeof arg !== 'object').join(''),
  // Arguments: {address, city, subdivision, postalCode, countryCode}
  // formatAddress: (...args) => addressFormat(args).join(' '),
  formatAddress: (...args) => args.filter(arg => typeof arg !== 'object').join(' '),
  formatDate: date => moment(date).format('MM/YYYY'),
  // Consecutive entries with the same company become one {name, website, showWebsite, description, roles}
  groupWork: work =>
    work.reduce((groups, role) => {
      const last = groups[groups.length - 1];
      if (last && role.name && last.name === role.name) last.roles.push(role);
      else groups.push({ name: role.name, website: role.url, showWebsite: role.showWebsite, description: role.description, roles: [role] });
      return groups;
    }, []),
  lowercase: s => s.toLowerCase(),
  eq: (a, b) => a === b,
  // A phone arrives as RFC 3966 (tel:+27-21-555-0100)
  tel: p => (p || '').replace(/^tel:/, ''),
});

function render(resume) {
  const dir = `${__dirname}/src`;
  const css = fs.readFileSync(`${dir}/style.css`, 'utf-8');
  const resumeTemplate = fs.readFileSync(`${dir}/resume.hbs`, 'utf-8');

  const Handlebars = handlebarsWax(handlebars);

  Handlebars.partials(`${dir}/partials/**/*.{hbs,js}`);

  return Handlebars.compile(resumeTemplate)({
    style: `<style>${css}</style>`,
    resume,
  });
}

module.exports = {
  render,
};
